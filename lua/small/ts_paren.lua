local M={ns=vim.api.nvim_create_namespace('lua-as-lisp')}
function M.run()
    local parser=assert(vim.treesitter.get_parser())
    local root=parser:parse()[1]:root()
    local nodes={root}
    while true do
        ---@type TSNode|nil
        local node=table.remove(nodes,1)
        if not node then return end
        local rows,cols,rowe,cole=node:range()
        if node:named_child(1) then
            vim.api.nvim_buf_set_extmark(0,M.ns,rows,cols,{virt_text={{'('}},virt_text_pos='inline'})
            vim.api.nvim_buf_set_extmark(0,M.ns,rowe,cole,{virt_text={{')'}},virt_text_pos='inline'})
        end
        vim.list_extend(nodes,node:named_children())
    end
end
return M
