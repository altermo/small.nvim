local M={}
function M.select(node)
    local rows,cols,rowe,cole=node:range()
    vim.api.nvim_win_set_cursor(0,{rows+1,cols})
    vim.api.nvim_feedkeys(vim.keycode'<esc>v','nx',true)
    vim.api.nvim_win_set_cursor(0,{rowe+1,cole-1})
end
function M.get_node()
    local node=assert(vim.treesitter.get_node())
    local pos1=vim.fn.getpos('v')
    local pos2=vim.fn.getpos('.')
    if pos1[2]>pos2[2] or (pos1[2]==pos2[2] and pos1[3]>pos2[3]) then
        pos1,pos2=pos2,pos1
    end
    local r={pos1[2]-1,pos1[3]-1,pos2[2]-1,pos2[3]}
    local parent=assert(node:parent())
    while vim.treesitter.node_contains(parent,r) do
        node=parent
        parent=assert(node:parent())
    end
    return node
end
function M.next()
    local node=M.get_node()
    if node:next_named_sibling() then
        M.select(node:next_named_sibling())
    end
end
function M.prev()
    local node=M.get_node()
    if node:prev_named_sibling() then
        M.select(node:prev_named_sibling())
    end
end
if vim.dev then
    vim.keymap.set('x','<C-l>',M.next)
    vim.keymap.set('x','<C-h>',M.prev)
end
return M
