---@diagnostic disable: param-type-mismatch
local M={}
local function getword(x1,x2,y) return vim.fn.strcharpart(vim.fn.getline(y),x1,x2-x1+1) end
function M.wordcolumn()
    local reg=vim.region(0,'v','.','',false)
    if vim.tbl_count(reg)>1 then return end
    local beg,pos=next(reg)
    local _end=beg
    local col1,col2=unpack(pos)
    local word=getword(col1,col2,".")
    while beg>=1 and getword(col1,col2,beg)==word do beg=beg-1 end
    while _end<vim.fn.line("$") and getword(col1,col2,_end+1)==word do _end=_end+1 end
    return '<esc>'..(beg+1)..'gg'..(col1+1)..'|<C-v>o'.._end..'gg'..(col2+1)..'|'
end
function M.charcolumn() return M.wordcolumn()..vim.v.operator end
local function getchar(x,y) return vim.fn.strcharpart(vim.fn.getline(y+1),x,1) end
function M.wordrow()
    local reg=vim.region(0,'v','.','',false)
    if vim.tbl_count(reg)>1 then return end
    local line,pos=next(reg)
    local col1,col2=unpack(pos)
    local char=getchar(col1,line)
    while col1>=1 and getchar(col1-1,line)==char do col1=col1-1 end
    while col2<#vim.fn.getline(line+1) and getchar(col2,line)==char do col2=col2+1 end
    return '<esc>'..(col1+1)..'|<C-v>o'..col2..'|'
end
function M.charrow() return M.wordrow()..vim.v.operator end
return M
