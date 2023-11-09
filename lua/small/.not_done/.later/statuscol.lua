local M={
    fold={' ','▎','▍','▌','▋','▊','▉','█','▐'},
}
function M.transform(n)
    local l={['0']='₀',['1']='₁',['2']='₂',['3']='₃',['4']='₄',['5']='₅',['6']='₆',['7']='₇',['8']='₈',['9']='₉'}
    local h={['0']='⁰',['1']='¹',['2']='²',['3']='³',['4']='⁴',['5']='⁵',['6']='⁶',['7']='⁷',['8']='⁸',['9']='⁹'}
    local top=tostring(math.floor(n%100/10))
    local bot=tostring(n%10)
    if n<100 then return n end
    if n<200 then return top..l[bot] end
    if n<300 then return top..h[bot] end
    if n<400 then return l[top]..bot end
    if n<500 then return l[top]..l[bot] end
    if n<600 then return l[top]..h[bot] end
    if n<700 then return h[top]..bot end
    if n<800 then return h[top]..l[bot] end
    if n<900 then return h[top]..h[bot] end
    return n
end
M.MyStatuscol=function()
    local line=vim.v.lnum
    local ret=''
    if vim.o.foldenable then
        ret=M.fold[vim.fn.foldlevel(line)+1] or '|'
    end
    ret=ret..'%C%s'
    local num=''
    if vim.v.virtnum==0 then
        num=M.transform(0)
        if vim.o.number then
            num=M.transform(line)
        end
        if vim.o.relativenumber and vim.v.relnum>0 then
            num=M.transform(vim.v.relnum)
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
