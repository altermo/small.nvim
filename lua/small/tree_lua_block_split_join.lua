local M={}
function M.wrapp_toggle_statement(times)
    return function(node)
        local start={}
        for i=0,times do
            table.insert(start,vim.treesitter.get_node_text(node:child(i),0))
        end
        local ret={table.concat(start,' ')}
        for i in node:child(times+1):iter_children() do
            table.insert(ret,vim.treesitter.get_node_text(i,0))
        end
        vim.pprint(node)
        table.insert(ret,vim.treesitter.get_node_text(node:child(times+2),0))
        if vim.treesitter.get_node_text(node,0):find'\n' then
            return {table.concat(ret,' ')}
        else
            return ret,{format=true}
        end
    end
end
M.nodes={
    if_statement=M.wrapp_toggle_statement(2),
    for_statement=M.wrapp_toggle_statement(2),
    function_definition=M.wrapp_toggle_statement(1),
}
function M.run()
    local node=vim.treesitter.get_node()
    if not node then return end
    if not M.nodes[node:type()] then return end
    local lines,act=M.nodes[node:type()](node)
    act=act or {}
    local srow,scol,erow,ecol=node:range()
    vim.api.nvim_win_set_cursor(0,{srow+1,scol})
    vim.lsp.util.apply_text_edits({{newText=table.concat(lines,'\n'),range={start={line=srow,character=scol},['end']={line=erow,character=ecol}}}},0,'utf-8')
    if act.format then vim.cmd('silent! normal! '..#lines..'==') end
end
if vim.dev then
    vim.keymap.set('n','gS',M.run)
end
return M
