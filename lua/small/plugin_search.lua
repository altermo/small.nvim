local M={}
function M.handle_plugin(path)
    vim.opt.runtimepath:append(path)
    pcall(vim.cmd.helptags,path..'/doc')
    vim.cmd.vnew(path)
end
function M.run()
    if not M.cache then
        vim.system({'curl','https://nvim.sh/s'},{},function (out)
            M.cache=out.stdout
            vim.schedule(M.run)
        end) return
    end
    local ret={}
    for _,v in ipairs(vim.split(M.cache,'\n')) do
        table.insert(ret,({string.gsub(v,'^(%S+%s+)%S*%s*%S*%s*%S*%s*%S+%s*(.-) *$','%1%2')})[1])
    end
    table.remove(ret,1)
    require'small.lib.select'(ret,{},function (index)
        if not index then return end
        local url=index:gsub('^(%S+).*$','%1')
        local tmp=vim.fn.tempname()..'/'
        vim.fn.setreg('+',url)
        vim.system({'git','clone','--depth=1','https://github.com/'..url,tmp},{},function ()
            vim.schedule_wrap(M.handle_plugin)(tmp)
        end)
    end)
end
if vim.dev then
    M.cache=_G._CACHE
    M.search_plugins()
    _G._CACHE=M.cache
end
return M
