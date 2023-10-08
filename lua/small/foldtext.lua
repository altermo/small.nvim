local M={}
function M.MyFoldText()
    local bul='•'
    local wininfo=vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
    local line=vim.fn.getline(vim.v.foldstart) --[[@as string]]
    local ident=line:match('^[%s-]*')
    local left=('%s%s '):format(#ident>0 and bul:rep(#ident-1)..' ' or '',line:sub(#ident+1))
    local precent=(vim.v.foldend-vim.v.foldstart+1)/vim.api.nvim_buf_line_count(0)*100
    local right=string.format(
        ' %d lines:%3s%% %s',
        vim.v.foldend-vim.v.foldstart+1,
        precent<1 and tostring(precent):sub(2,3) or math.floor(precent),
        bul:rep(3))
    local len=#vim.str_utf_pos(left)+wininfo.textoff+#vim.str_utf_pos(right)
    local middle=bul:rep(wininfo.width-len)
    return left..middle..right
end
function M.setup()
    _G.MyFoldText=M.MyFoldText
    vim.o['foldtext']='v:lua.MyFoldText()'
end
return M
