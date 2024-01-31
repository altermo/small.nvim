-- Only run specific formatter/diagnostic when root dir contains config file
local M={ns=vim.api.nvim_create_namespace('small_formatter_stylua')}
M.formatters={
    {
        name='uncrustify',
        ft={'c','cpp'},
        conf_files={'.uncrustify.cfg','uncrustify.cfg'}
    },
    {
        name='stylua',
        ft={'lua'},
        conf_files={'stylua.toml','.stylua.toml'}
    },
    {
        name='luacheck',
        ft={'lua'},
        conf_files={'.luacheckrc'},
        run=function (v,conf,file)
            if M.luacheck_job then M.luacheck_job:wait() end
            M.luacheck_job=vim.system({'luacheck','--codes','--ranges','--formatter','plain','--',file},{cwd=vim.fs.dirname(conf)},vim.schedule_wrap(function (ev)
                local diagnostics={}
                for line in vim.gsplit(ev.stdout,'\n',{trimempty=true}) do
                    local row,col,end_col,mes=line:match('^[^:]+:(%d+):(%d+)%-(%d+): %(%w*%) (.*)')
                    table.insert(diagnostics,{
                        col=tonumber(col)-1,
                        end_col=tonumber(end_col),
                        lnum=tonumber(row)-1,
                        message='luacheck: '..mes,
                        severity=vim.diagnostic.severity.HINT,
                    })
                end
                vim.diagnostic.set(M.ns,v.buf,diagnostics)
                vim.api.nvim_create_autocmd({'TextChanged','TextChangedI'},{buffer=v.buf,once=true,callback=function ()
                    if M.luacheck_job then M.luacheck_job:wait() end
                    vim.diagnostic.set(M.ns,v.buf,{})
                end})
            end))
        end,
    }

}
function M.find_files(files,cwd)
    return vim.fs.find(files,{type='file',upward=true,path=cwd})[1]
end
function M.format(v,conf,file)
    if v.name=='uncrustify' then
        vim.system({v.name,'--no-backup','-c',conf,'-o',file,'-f',file},{cwd=vim.fs.dirname(conf)}):wait()
    else
        vim.system({v.name,'--',file},{cwd=vim.fs.dirname(conf)}):wait()
    end
end
function M.run()
    local buf=vim.api.nvim_get_current_buf()
    local file=vim.api.nvim_buf_get_name(buf)
    if not vim.fn.filereadable(file) then return end
    local format=false
    for _,v in ipairs(M.formatters) do
        v=setmetatable({buf=buf},{__index=v})
        if not vim.fn.executable(v.name) then goto continue end
        if not vim.tbl_contains(v.ft,vim.bo[buf].filetype) then goto continue end
        local conf=M.find_files(v.conf_files,vim.fs.dirname(file))
        if not conf then goto continue end
        do (v.run or M.format)(v,conf,file) end
        if not v.run then format=true end
        ::continue::
    end
    if format==false then
        vim.api.nvim_buf_call(buf,vim.lsp.buf.format)
    end
end
if vim.dev then
    M.run()
end
return M
