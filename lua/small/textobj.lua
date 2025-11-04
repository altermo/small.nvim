---@diagnostic disable: param-type-mismatch
local M={}
function M.getword(x1,x2,line)
    local offset=vim.str_utf_pos(line)
    return #line>=x2 and line:sub(offset[x1],offset[x2]+vim.str_utf_end(line,offset[x2])) or ''
end
function M.wordcolumn()
    local beg=vim.fn.line('.')
    local _end=vim.fn.line('v')
    if beg~=_end then return end
    local col1=vim.fn.virtcol('.')
    local col2=vim.fn.virtcol('v')
    if col2<col1 then col1,col2=col2,col1 end
    local line=vim.api.nvim_get_current_line()
    local word=M.getword(col1,col2,line)
    while beg>=1 and M.getword(col1,col2,vim.fn.getline(beg))==word do beg=beg-1 end
    while _end<vim.fn.line("$") and M.getword(col1,col2,vim.fn.getline(_end+1))==word do _end=_end+1 end
    return '<esc>'..(beg+1)..'gg'..col1..'|<C-v>o'.._end..'gg'..col2..'|'
end
function M.charcolumn() return M.wordcolumn()..vim.v.operator end
function M.wordrow()
    if vim.fn.line('.')~=vim.fn.line('v') then return end
    local col1=vim.fn.virtcol('.')
    local col2=vim.fn.virtcol('v')
    if col1~=col2 then return end
    local line=vim.api.nvim_get_current_line()
    local char=M.getword(col1,col2,line)
    while col1>1 and M.getword(col1-1,col1-1,line)==char do col1=col1-1 end
    while col2<#line and M.getword(col2+1,col2+1,line)==char do col2=col2+1 end
    return '<esc>'..col1..'|<C-v>o'..col2..'|'
end
function M.charrow() return M.wordrow()..vim.v.operator end

function M.samecolumn()
    if vim.fn.mode()=='n' then
        return M.charcolumn()
    end
    return M.wordcolumn()
end
function M.samerow()
    if vim.fn.mode()=='n' then
        return M.charrow()
    end
    return M.wordrow()
end

return M
