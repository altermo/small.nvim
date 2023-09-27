--TODO: instead of using inode, use count as nodes may change when doing many M.over()
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
    if not node then return false end
    M.save={prev,node,other}
    require'nvim-treesitter.ts_utils'.swap_nodes(node,other,0)
end
function M.over()
    if not M.save then return end
    local prev,node,other=unpack(M.save)
    require'nvim-treesitter.ts_utils'.swap_nodes(node,other,0)
    if not M.swap(prev,node:parent()) then M.save=nil end
end
function M.swap_prev() M.swap(true) end
function M.swap_next() M.swap() end
return M
