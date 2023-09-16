local M={}
M.MyTabLine=function()
    local curtab = vim.fn.tabpagenr()
    local line = ''
    for i, _ in ipairs(vim.fn.gettabinfo()) do
        local file=vim.fn.bufname(vim.fn.tabpagebuflist(i)[vim.fn.tabpagewinnr(i)])
        local char=((file=='' or not file) and 'N') or
        (file:match'^term://' and
        (file:match'ranger' and 'R' or 'T')) or
        (#file>20 and (
        #(vim.fs.basename(file) or '')>20
        and (vim.fs.basename(file):sub(1,17)..'...')
        or '...'..file:sub(-17))) or file
        line=line..(i==curtab and '%#TabLineSel#' or '%#TabLine#')..'\226\157\172'..char..'\226\157\173' --❬❭❮❯❰❱
    end
    return line..'%#TabLine#'
end
function M.setup()
    _G.MyTabLine=M.MyTabLine
    vim.o['tabline']='%!v:lua.MyTabLine()'
end
return M
