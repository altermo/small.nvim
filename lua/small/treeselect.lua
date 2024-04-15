--- similar to helix's treesitter mappings (except ignore unnamed nodes)
local M={}
M.stack={}
function M.select(node)
    local rows,cols,rowe,cole=node:range()
    vim.api.nvim_win_set_cursor(0,{rows+1,cols})
    vim.api.nvim_feedkeys(vim.keycode'<C-\\><C-n>v','nx',true)
    if not pcall(vim.api.nvim_win_set_cursor,0,{rowe+1,cole-1}) then
        vim.api.nvim_win_set_cursor(0,{rowe,#vim.fn.getline(rowe)})
    end
end
local function same_range(r1,r2)
    return r1[1]==r2[1] and r1[2]==r2[2] and r1[3]==r2[3] and r1[4]==r2[4]
end
function M.get_node()
    local node=vim.treesitter.get_node()
    local pos1=vim.fn.getpos('v')
    local pos2=vim.fn.getpos('.')
    if pos1[2]>pos2[2] or (pos1[2]==pos2[2] and pos1[3]>pos2[3]) then
        pos1,pos2=pos2,pos1
    end
    local r={pos1[2]-1,pos1[3]-1,pos2[2]-1,pos2[3]}
    while node do
        local nr={node:range()}
        if (r[1]>nr[1] or (r[1]==nr[1] and r[2]>=nr[2])) and
            (r[3]<nr[3] or (r[3]==nr[3] and r[4]<=nr[4])) then
            local parent=node:parent()
            while parent do
                local pr={parent:range()}
                if not same_range(nr,pr) then
                    return node
                end
                node=parent
                parent=node:parent()
            end
            return node
        end
        node=node:parent()
    end
    return vim.treesitter.get_parser():trees()[1]:root()
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
function M.up()
    local node=M.get_node()
    if not node:parent() then return end
    table.insert(M.stack,{{node:parent():range()},node})
    M.select(node:parent())
end
function M.down()
    local node=M.get_node()
    if #M.stack>0 and same_range({node:range()},M.stack[#M.stack][1]) then
        M.select(table.remove(M.stack)[2])
        return
    end
    M.stack={}
    local child=node:named_child(0)
    while child and same_range({child:range()},{node:range()}) do
        child=child:named_child(0)
    end
    if not child then return end
    M.select(child)
end
function M.current()
    M.select(M.get_node())
end
function M.line()
    vim.fn.cursor(vim.fn.line'.',1)
    M.select(M.get_node())
end
return M
