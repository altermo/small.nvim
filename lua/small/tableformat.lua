local M={}
function M.getline(lnum)
    return vim.fn.getline(lnum) --[[@as string]]
end
function M.run()
    if not vim.api.nvim_get_current_line():match('^%s*|') then return end
    local rowe=vim.fn.line'.'
    while M.getline(rowe+1):match('^%s*|') do rowe=rowe+1 end
    local rows=vim.fn.line'.'
    while M.getline(rows-1):match('^%s*|') do rows=rows-1 end
    local lines=vim.api.nvim_buf_get_lines(0,rows-1,rowe,false)
    local currow=vim.fn.line'.'-rows+1
    local curline=lines[currow]
    local count=vim.fn.count(curline:sub(1,vim.fn.col'.'),'|')
    local indent=curline:match('^%s*')
    local tbl={}
    for k,line in ipairs(lines) do
        local t={}
        if line:match'^%s*|%-*[|-]*$' then
            t.is_sep=true
        end
        while line:find'|' do
            line=line:sub(line:find'|'+1)
            t[#t+1]=vim.trim(line:find'|' and line:sub(1,line:find'|'-1) or line)
        end
        tbl[k]=t
    end
    local tmax={}
    for _,t in ipairs(tbl) do
        for k,v in ipairs(t.is_sep and {} or t) do
            if not tmax[k] or vim.api.nvim_strwidth(v)>tmax[k] then tmax[k]=vim.api.nvim_strwidth(v) end
        end
    end
    local mlines={}
    for _,t in ipairs(tbl) do
        local o={}
        if t.is_sep then
            for _,max in ipairs(tmax) do table.insert(o,('-'):rep(max+2)) end
            o[#o]=''
        else
            for k,max in ipairs(tmax) do
                local line=t[k] or ''
                table.insert(o,' '..line..(' '):rep(max-vim.api.nvim_strwidth(line)+1))
            end
        end
        mlines[#mlines+1]=o
    end
    local olines={}
    for _,line in ipairs(mlines) do
        table.insert(olines,indent..vim.trim('|'..table.concat(line,'|')))
    end
    local x=vim.api.nvim_strwidth(indent)+1
    for _,line in ipairs{unpack(mlines[currow],1,count)} do
        x=x+vim.api.nvim_strwidth(line)+1
    end
    vim.schedule(function ()
        vim.api.nvim_buf_set_lines(0,rows-1,rowe,false,olines)
        vim.api.nvim_win_set_cursor(0,{vim.fn.line'.',x})
    end)
    return true
end
if vim.dev then
    M.run()
end
return M
