local M={conf={nodes={
    arguments=true,
    parameters=true,
    argument_list=true,
    table_constructor=true,
    list=true,
    array=true,
}}}
function M.get_node(prev,node)
    if not node then return end
    local parent=node:parent()
    while parent and (not M.conf.nodes[parent:type()] or not (prev and node:prev_named_sibling() or node:next_named_sibling())) do
        node=parent
        parent=node:parent()
    end
    return parent and node,prev and node:prev_named_sibling() or node:next_named_sibling()
end
function M.swap(prev,inode)
    local node,other=M.get_node(prev,inode or vim.treesitter.get_node())
    if not node then return end
    M.save={prev,node}
    require'nvim-treesitter.ts_utils'.swap_nodes(node,other,0)
end
function M.over()
    if not M.save then return end
    local prev,node=M.save[1],M.save[2]
    M.swap(prev,node)
    M.swap(prev,node:parent())
end
function M.swap_prev() M.swap(true) end
function M.swap_next() M.swap() end
return M
