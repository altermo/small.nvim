local M={}
function M.handle_plugin(path)
    vim.opt.runtimepath:append(path)
    local select=vim.fn.readdir(path..'/lua')
    pcall(vim.cmd.helptags,'ALL')
    if #select==0 then return end
    vim.ui.select(select,{},function (inp)
        if not inp then return end
        if not pcall(require,inp) then
          package[inp]=nil
        end
    end)
end
function M.run()
    M.cache=M.cache or vim.system({'curl','https://nvim.sh/s'}):wait().stdout
    local ret={}
    for _,v in ipairs(vim.split(M.cache,'\n')) do
        table.insert(ret,({string.gsub(v,'^(%S+%s+)%S*%s*%S*%s*%S*%s*%S+%s*(.-) *$','%1%2')})[1])
    end
    table.remove(ret,1)
    vim.ui.select(ret,{},function (index)
        if not index then return end
        local url=index:gsub('^(%S+).*$','%1')
        local tmp=vim.fn.tempname()..'/'
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