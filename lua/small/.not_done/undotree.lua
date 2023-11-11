local M={}
function M._create_undotree(buf)
    local info={}
    vim.api.nvim_buf_call(buf,function ()
        vim.cmd'silent undo 0'
        table.insert(info,vim.api.nvim_buf_get_lines(buf,0,-1,false))
        for _,v in ipairs(vim.fn.undotree().entries) do
            vim.cmd("silent undo "..v.seq)
            table.insert(info,vim.api.nvim_buf_get_lines(buf,0,-1,false))
        end
    end)
    return info
end
if vim.dev then
    local buf=vim.fn.bufnr('temp.md')
    vim.pprint(M._create_undotree(buf))
end
return M
