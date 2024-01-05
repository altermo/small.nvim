local M={
    ns=vim.api.nvim_create_namespace('small_treejump'),
    nodes={},
}
function M.range_eq(r1,r2)
    return r1[1]==r2[1] and r1[2]==r2[2] and r1[3]==r2[3] and r1[4]==r2[4]
end
function M.split_range_by_range(r,rsplit)
    local srow,scol,erow,ecol=unpack(r)
    local rsrow,rscol,rerow,recol=unpack(rsplit)
    return {srow,scol,rsrow,rscol},{rerow,recol,erow,ecol}
end
function M.highlight(range,name)
    local srow,scol,erow,ecol=unpack(range)
    vim.highlight.range(0,M.ns,name,{srow,scol},{erow,ecol})
end
function M.run()
    local node=vim.treesitter.get_node()
    if not node then return end
    local nodes={}
    while node do
        if node:named() and (not node:parent() or not M.range_eq({node:range()},{node:parent():range()})) then
            table.insert(nodes,1,node)
        end
        node=node:parent()
    end
    M.nodes={}
    for k,v in ipairs(nodes) do
        local r1,r2
        if nodes[k+1] then
            r1,r2=M.split_range_by_range({v:range()},{nodes[k+1]:range()})
        else
            r1={v:range()}
        end
        local function hig(col)
            M.highlight(r1,col)
            if r2 then M.highlight(r2,col) end
        end
        hig('rainbowr'..(k%6+1))
        M.nodes.last=(k%6+1)
        M.nodes.prev=M.nodes[k%6+1]
        M.nodes[k%6+1]={v:range()}
    end
end
function M.hex_to_number(hex)
    if type(hex)=='number' then hex=('#%06x'):format(hex) end
    local r,g,b=hex:match('#(..)(..)(..)')
    return tonumber(r,16),tonumber(g,16),tonumber(b,16)
end
function M.number_to_hex(r,g,b)
    return string.format('#%02x%02x%02x',r,g,b)
end
function M.blend(col1,col2,t)
    local rf,gf,bf=M.hex_to_number(col1)
    local rt,gt,bt=M.hex_to_number(col2)
    return M.number_to_hex(rt*t+rf*(1-t),gt*t+gf*(1-t),bt*t+bf*(1-t))
end
function M.goto_node(n)
    if not M.nodes[n] then return end
    local srow,scol,erow,ecol=unpack(M.nodes[n])
    return '<esc>'..(srow+1)..'gg'..(scol+1)..'|vo'..(erow+1)..'gg'..ecol..'|'
end
function M.jump_color()
    M.nodes[M.nodes.last]=M.nodes.prev
    return M.goto_node(M.nodes.last)
end
if vim.dev then
    vim.keymap.set('n','vr',function () return M.goto_node(1) end,{expr=true})
    vim.keymap.set('n','vo',function () return M.goto_node(2) end,{expr=true})
    vim.keymap.set('n','vy',function () return M.goto_node(3) end,{expr=true})
    vim.keymap.set('n','vg',function () return M.goto_node(4) end,{expr=true})
    vim.keymap.set('n','vb',function () return M.goto_node(5) end,{expr=true})
    vim.keymap.set('n','vp',function () return M.goto_node(6) end,{expr=true})
    vim.keymap.set('x','H',function () return M.jump_color() end,{expr=true})
    vim.api.nvim_create_autocmd({'CursorMoved','CursorMovedI'},{callback=function ()
        for i=1,6 do
            local col1=vim.api.nvim_get_hl(0,{name='rainbow'..i}).fg
            local col2=vim.api.nvim_get_hl(0,{name='normal'}).bg
            vim.api.nvim_set_hl(0,'rainbowr'..i,{bg=M.blend(col1,col2,0.75),blend=0})
        end
        vim.api.nvim_buf_clear_namespace(0,M.ns,0,-1)
        M.run()
    end,group=vim.api.nvim_create_augroup('small_treejump',{})})
end
return M
