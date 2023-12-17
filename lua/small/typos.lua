local M={ns=vim.api.nvim_create_namespace'small_typos'}
function M.update(buf)
    buf=buf or 0
    local lines=vim.api.nvim_buf_get_lines(buf,0,-1,false)
    if M.job then M.job:wait() end
    M.job=vim.system({'typos','-','--format=json'},{stdin=lines},vim.schedule_wrap(function (ev)
        vim.diagnostic.set(M.ns,buf,vim.iter(vim.split(ev.stdout,'\n',{trimempty=true})):map(vim.json.decode):map(function (json)
            return {
                col=json.byte_offset,
                end_col=json.byte_offset+#json.typo,
                lnum=json.line_num-1,
                message=('typo: `%s` => `%s`'):format(json.typo,table.concat(json.corrections,'`, `')),
                severity=vim.diagnostic.severity.HINT,
            }
        end):totable())
    end))
end
function M.setup()
    vim.api.nvim_create_autocmd({'TextChanged','InsertLeave','BufEnter'},{callback=function (ev)
        M.update(ev.buf)
    end,group=vim.api.nvim_create_augroup('small_typos',{clear=true})})
end
if vim.dev then
    M.setup()
end
return M
