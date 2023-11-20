local M={}
function M.getline(lnum)
    return vim.fn.getline(lnum) --[[@as string]]
end
function M.run(char)
    if char~='|' then return end
    if not vim.api.nvim_get_current_line():match('^%s*|') then return end
    local rowe=vim.fn.line'.'
    while M.getline(rowe+1):match('^%s*|') do rowe=rowe+1 end
    local rows=vim.fn.line'.'
    while M.getline(rows-1):match('^%s*|') do rows=rows-1 end
    local lines=vim.api.nvim_buf_get_lines(0,rows-1,rowe,false)
    lines[vim.fn.line'.'-rows+1]=lines[vim.fn.line'.'-rows+1]..'|'
    local tbl={}
    for _,v in ipairs(lines) do
        if v:match('^%s*[-|]*$') then
            table.insert(tbl,'-')
        else
            local r={}
            for i in v:gmatch('([^|]*)|') do
                table.insert(r,i)
            end
            table.remove(r,1)
            table.insert(tbl,r)
        end
    end
    local max={}
    for _,v in ipairs(tbl) do
        for k,i in ipairs(type(v)=='table' and v or {}) do
            if (max[k] or 0)<#i then max[k]=#i end
        end
    end
    local long='|'
    for _,v in pairs(max) do
        long=long..('-'):rep(v+1)..'|'
    end
    local rlines={}
    for _,v in ipairs(tbl) do
        if v=='-' then
            table.insert(rlines,long)
        else
            local line='|'
            for k,i in ipairs(v) do
                line=line..i..(' '):rep(max[k]-#i)..'|'
            end
            table.insert(rlines,line)
        end
    end
    vim.schedule(function ()
        vim.api.nvim_buf_set_lines(0,rows-1,rowe,false,rlines)
    end)
    return true
end
function M.toggle()
    if M.is_enabled then M.disable() else M.enable() end
end
function M.enable()
    M.is_enabled=true
    M.au=vim.api.nvim_create_autocmd('InsertCharPre',{
        callback=function ()
            if M.run(vim.v.char) then vim.v.char='' end
        end,
        group=vim.api.nvim_create_augroup('small.tablemode',{})
    })
end
function M.disable()
    M.is_enabled=false
end
if vim.dev then
    M.enable()
end
return M
--[[

|af|
|b |
|c |
--]]
