local M={
    fold={' ','▎','▍','▌','▋','▊','▉','█','▐'},
}
M.MyStatuscol=function()
    local line=vim.v.lnum
    local ret=''
    if vim.o.foldenable then
        ret=M.fold[vim.fn.foldlevel(line)+1] or '|'
    end
    ret=ret..'%C%s'
    local num=''
    if vim.v.virtnum==0 then
        num='0'
        if vim.o.number then
            num=line
        end
        if vim.o.relativenumber and vim.v.relnum>0 then
            num=vim.v.relnum
        end
    end
    ret=ret..num
    return ret
end
function M.setup()
    vim.o.numberwidth=2
    _G.MyStatuscol=M.MyStatuscol
    vim.o['statuscolumn']='%!v:lua.MyStatuscol()'
end
if vim.dev then
    M.setup()
end
return M
