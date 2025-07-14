local M={ns=vim.api.nvim_create_namespace'small_fendy'}
function M.refresh()
    if not M.buf then return end
    if not vim.api.nvim_buf_is_valid(M.buf) then return end
    local inlines=vim.api.nvim_buf_get_lines(M.buf,0,-1,false)
    for k,v in ipairs(inlines) do
        v=v:gsub('²','^2')
        v=v:gsub('³','^3')
        inlines[k]=('println(%s)'):format(v)
    end
    if M.sys then
        M.sys:kill(9)
    end
    M.sys=vim.system({'fend','-e',table.concat(inlines,';')},{},vim.schedule_wrap(function (out)
        vim.api.nvim_buf_clear_namespace(M.buf,M.ns,0,-1)
        if out.code~=0 or out.stderr~='' then
            return
        end
        local lines=vim.split(out.stdout,'\n')
        table.remove(lines)
        for row,v in pairs(lines) do
            vim.api.nvim_buf_set_extmark(M.buf,M.ns,row-1,0,{virt_text={{v,'Comment'}}})
        end
    end))
end
function M.run()
    M.buf=vim.api.nvim_create_buf(false,true)
    vim.bo[M.buf].bufhidden='wipe'
    vim.bo[M.buf].filetype='javascript'
    vim.api.nvim_create_autocmd({'TextChanged','TextChangedI','TextChangedP'},{buffer=M.buf,callback=M.refresh})
    vim.api.nvim_open_win(M.buf,true,{
        split='right'
    })
end
return M
