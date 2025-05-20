--- similar to helix's treesitter mappings (except ignore unnamed nodes)
local M={}
M.stack={}
local _treeview_cache
local _cache_check={
    bufnr=-1,
    changedtick=-1,
}
local function cache_check()
    if vim.api.nvim_get_current_buf()==_cache_check.bufnr
        and vim.b.changedtick==_cache_check.changedtick then
        return
    end
    M.stack={}
    _treeview_cache=nil
    _cache_check={
        bufnr=vim.api.nvim_get_current_buf(),
        changedtick=vim.b.changedtick,
    }
end
---@return table,table,table
local function create_treeview()
    if _treeview_cache then
        return _treeview_cache.view,_treeview_cache.injections,_treeview_cache.rinjections
    end
    local parser=assert(vim.treesitter.get_parser())
    local injections={}
    local rinjections={}
    parser:for_each_tree(function(parent_tree,parent_ltree)
        local parent=parent_tree:root()
        for _,child in pairs(parent_ltree:children()) do
            for _,child_tree in pairs(child:trees()) do
                local child_root=child_tree:root()
                if vim.treesitter.node_contains(parent,{child_root:range()}) then
                    local node=assert(parent:named_descendant_for_range(child_root:range()))
                    local id=node:id()
                    if not injections[id] or child_root:byte_length()>injections[id]:byte_length() then
                        injections[id]=child_root
                        rinjections[child_root:id()]=node
                    end
                end
            end
        end
    end)
    local view={}
    _treeview_cache={
        view=view,
        injections=injections,
        rinjections=rinjections,
    }
    return view,injections,rinjections
end
---@param a TSNode
---@param b TSNode
---@return boolean
local function same_range(a,b)
    local arows,acols,arowe,acole=a:range()
    local brows,bcols,browe,bcole=b:range()
    return arows==brows and acols==bcols and arowe==browe and acole==bcole
end
---@return TSNode
function M.get_node()
    cache_check()
    local pos1=vim.fn.getpos('v')
    local pos2=vim.fn.getpos('.')
    if pos1[2]>pos2[2] or (pos1[2]==pos2[2] and pos1[3]>pos2[3]) then
        pos1,pos2=pos2,pos1
    end
    local range={pos1[2]-1,pos1[3]-1,pos2[2]-1,pos2[3]}
    local parser=assert(vim.treesitter.get_parser())
    parser:parse(true)
    local node=assert(parser:named_node_for_range(range,{ignore_injections=false}))
    return node
end
---@param node TSNode
---@param _rec any?
---@return table
local function get_data(node,_rec)
    local view,injections,rinjections=create_treeview()
    if view[node:id()] then
        return view[node:id()]
    end

    assert(node:byte_length()~=0)

    local parent=rinjections[node:id()] or node:parent() or nil
    if parent and same_range(node,parent) and not _rec then
        return get_data(parent)
    end

    local data=_rec or {}
    view[node:id()]=data

    data.children={}

    local injection=injections[node:id()]
    if injection then
        if injection:byte_length()~=0 then
            if same_range(injection,node) then
                get_data(injection,data)
            else
                table.insert(data.children,injection)
            end
        end
    end

    for _,child in ipairs(node:named_children()) do
        if child:byte_length()~=0 then
            if same_range(child,node) then
                get_data(child,data)
            else
                table.insert(data.children,child)
            end
        end
    end

    if not _rec then
        data.parent=parent
    end

    return data
end
---@param node TSNode
---@return TSNode
function M.get_parent_node(node)
    cache_check()
    local data=get_data(node)
    if not data.parent then
        return node
    end
    assert(not same_range(node,data.parent))
    return data.parent
end
---@param node TSNode
---@return TSNode
function M.get_child_node(node)
    cache_check()
    local data=get_data(node)
    for _,child in ipairs(data.children) do
        assert(not data.parent or not same_range(node,data.parent))
        assert(child:byte_length()~=0)
        return child
    end
    return node
end
---@param node TSNode
---@param prev boolean
---@return TSNode
function M.get_sibling_node(node,prev)
    cache_check()
    local data=get_data(node)
    local parent=data.parent
    if not parent then
        return node
    end
    local parent_data=get_data(parent)
    local idx=-1
    for i,child in ipairs(parent_data.children) do
        if get_data(child)==get_data(node) then
            idx=i+(prev and -1 or 1)
            break
        end
    end
    if parent_data.children[idx] then
        assert(not same_range(node,parent_data.children[idx]))
        assert(parent_data.children[idx]:byte_length()~=0)
        return parent_data.children[idx]
    end
    assert(not same_range(node,parent))
    return node
end
---@param node TSNode
function M.select(node)
    cache_check()
    local rows,cols,rowe,cole=node:range()
    vim.api.nvim_win_set_cursor(0,{rows+1,cols})
    vim.api.nvim_feedkeys(vim.keycode'<C-\\><C-n>v','nx',true)
    if not pcall(vim.api.nvim_win_set_cursor,0,{rowe+1,cole-1}) then
        vim.api.nvim_win_set_cursor(0,{rowe,#vim.fn.getline(rowe)})
    end
end
function M.up()
    cache_check()
    local node=M.get_node()
    local parent=M.get_parent_node(node)
    if get_data(parent)==get_data(node) then return end
    table.insert(M.stack,{parent,node})
    M.select(parent)
end
function M.down()
    cache_check()
    local node=M.get_node()
    if #M.stack>0 and same_range(node,M.stack[#M.stack][1]) then
        M.select(table.remove(M.stack)[2])
        return
    end
    M.stack={}
    local child=M.get_child_node(node)
    if get_data(child)==get_data(node) then return end
    M.select(child)
end
function M.next()
    cache_check()
    local node=M.get_node()
    local sibling=M.get_sibling_node(node,false)
    if get_data(sibling)==get_data(node) then return end
    M.select(sibling)
end
function M.prev()
    cache_check()
    local node=M.get_node()
    local sibling=M.get_sibling_node(node,true)
    if get_data(sibling)==get_data(node) then return end
    M.select(sibling)
end
function M.current()
    cache_check()
    M.select(M.get_node())
end
function M.line()
    cache_check()
    vim.fn.cursor(vim.fn.line'.',1)
    M.select(M.get_node())
end
return M
