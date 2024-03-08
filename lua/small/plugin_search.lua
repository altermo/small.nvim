local plugins=require'small.lib.plugins'
local M={}
function M.handle_plugin(path)
    vim.opt.runtimepath:append(path)
    pcall(vim.cmd.helptags,path..'/doc')
    vim.cmd.vnew(path)
end
function M.run(json)
    if not json then
        return plugins(M.run)
    end
    local items=vim.tbl_values(json.plugins)
    table.sort(items,function (a,b)
        return a.stars>b.stars
    end)
    local justlen=0
    for _,v in ipairs(items) do
        justlen=math.max(justlen,#v.id)
    end
    local just=(' '):rep(justlen+1)
    local opts={}
    opts.format_item=function (v)
        if v.description==vim.NIL then
            return v.id
        end
        return v.id..just:sub(#v.id)..v.description
    end
    require'small.lib.select'(items,opts,function (plug)
        if not plug then return end
        local tmp=vim.fn.tempname()..'/'
        vim.fn.setreg('+',plug.id)
        vim.system({'git','clone','--depth=1','https://github.com/'..plug.id,tmp},{},function ()
            vim.schedule_wrap(M.handle_plugin)(tmp)
        end)
    end)
end
if vim.dev then
    M.run()
end
return M
