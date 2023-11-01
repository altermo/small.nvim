local M={conf={treesitter=false}}
function M.GetTreesitterFoldText(just,fallback)
    if not M.conf.treesitter then
        fallback=fallback:sub(just)..' '
        local len=#vim.str_utf_pos(fallback)
        return {{fallback}},len
    end
    local foldtext=vim.treesitter.foldtext()
    if type(foldtext)=='string' then
        fallback=fallback:sub(just)..' '
        local len=#vim.str_utf_pos(fallback)
        return {{fallback}},len
    end
    local len=0
    for _,v in ipairs(foldtext) do
        len=len+#(v[1])
    end
    table.insert(foldtext,{' '})
    if just==1 then return foldtext,len end
    while just>0 do
        just=just-1
        if foldtext[1][1]=='' then
            table.remove(foldtext,1)
        else
            foldtext[1][1]=foldtext[1][1]:sub(2)
        end
    end
    return foldtext,len
end
function M.MyFoldText()
    local bul='•'
    local ret={}
    local wininfo=vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
    local line=vim.fn.getline(vim.v.foldstart) --[[@as string]]
    local ident=line:match('^[%s-]*')
    local indent=#ident>0 and bul:rep(#ident-1)..' ' or ''
    table.insert(ret,{indent})
    local left,leftlen=M.GetTreesitterFoldText(#ident+1,line)
    vim.list_extend(ret,left)
    local precent=(vim.v.foldend-vim.v.foldstart+1)/vim.api.nvim_buf_line_count(0)*100
    local right=string.format(
        ' %d lines:%3s%% %s',
        vim.v.foldend-vim.v.foldstart+1,
        precent<1 and tostring(precent):sub(2,3) or math.floor(precent),
        bul:rep(3))
    local len=#vim.str_utf_pos(indent)+leftlen+wininfo.textoff+#vim.str_utf_pos(right)
    local middle=bul:rep(wininfo.width-len)
    table.insert(ret,{middle})
    table.insert(ret,{right})
    return ret
end
function M.setup()
    _G.MyFoldText=M.MyFoldText
    vim.o['foldtext']='v:lua.MyFoldText()'
end
return M
