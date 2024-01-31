local M={}
function M.setup()
    vim.g.Nvim_color_cmdline=M.run
end
function M.run(cmdline)
    local parser=vim.treesitter.get_string_parser(cmdline,'vim')
    local tags={}
    for i=0,#cmdline do
        tags[i]={}
    end
    parser:parse(true)
    parser:for_each_tree(function(tree,ltree)
        local query=vim.treesitter.query.get(ltree:lang(),'highlights')
        if not query then return end
        for id,node in query:iter_captures(tree:root(),0,0,-1) do
            local name=query.captures[id]
            local _,scol,_,ecol=node:range()
            local hlid=vim.api.nvim_get_hl_id_by_name('@' .. name .. '.' .. ltree:lang())
            hlid=vim.fn.synIDtrans(hlid)
            local hl=vim.fn.synIDattr(hlid,'name')
            table.insert(tags[scol],{n=hl})
            table.insert(tags[ecol],1,{e=true,n=hl})
        end
    end)
    local stack={}
    local style={}
    for i=0,#cmdline do
        for _,v in ipairs(tags[i] or {}) do
            if v.e then
                table.remove(stack)
            else
                table.insert(stack,v.n)
            end
        end
        style[i]=stack[#stack]
    end
    local out={}
    local last=nil
    local last_pos
    for i=0,#cmdline do
        if last~=style[i] then
            if last_pos and last then
                table.insert(out,{last_pos,i,last})
            end
            last=style[i]
            last_pos=i
        end
    end
    return out
end
return M
