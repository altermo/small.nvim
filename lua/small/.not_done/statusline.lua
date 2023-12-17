local M={}
function M.MyStatusLine()
    return ''
end
function M.setup()
    _G.MyStatusLine=M.MyStatusLine
    vim.o['statusline']='%!v:lua.MyStatusLine()'
end
if vim.dev then
    M.setup()
end
return M
