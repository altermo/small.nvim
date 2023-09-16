local M={}
M.comments={
    lua='--%s',
    python='#%s',
    [true]='/*%s*/'
}
function M.get_ft()
    local stat,parser=pcall(vim.treesitter.get_parser,0)
    if not stat then return vim.o.filetype end
    local row=unpack(vim.api.nvim_win_get_cursor(0))
    return parser:language_for_range({row-1,-1,row-1,0}):lang()
end
function M.get_comment(ft)
    if M.comments[ft] then return M.comments[ft] end
    local comment=vim.filetype.get_option(ft,'commentstring')
    if comment~='' then return comment end
    return M.comments[true]
end
function M.comment_line(line,com)
    local indent=line:sub(1,(line:find('[^ ]') or 1)-1)
    local sline=line:sub(#indent+1)
    return indent..com:format(sline)
end
function M.uncomment_line(line,com)
    local coms=vim.trim(com:sub(1,com:find('%%s')-1))
    local come=vim.trim(com:sub(com:find('%%s')+2))
    local indent=line:sub(1,(line:find('[^ ]') or 1)-1)
    local sline=line:sub(#indent+1)
    return indent..sline:sub(#coms+1,(come~='' and -#come-1 or nil))
end
function M.is_commented(line,com)
    line=vim.trim(line)
    if line=='' then return false end
    local coms=vim.trim(com:sub(1,com:find('%%s')-1))
    local come=vim.trim(com:sub(com:find('%%s')+2))
    return line:sub(1,#coms)==coms and (come=='' or line:sub(-#come)==come)
end
function M.comment_lines(beg,fin)
    local lines=vim.api.nvim_buf_get_lines(0,beg,fin,false)
    local firstline=lines[1]
    local com=M.get_comment(M.get_ft())
    local iscom=M.is_commented(firstline,com)
    vim.api.nvim_buf_set_lines(0,beg,fin,false,
        vim.iter(lines):map(function (v)
            return (iscom and M.uncomment_line or M.comment_line)(v,com)
        end):totable())
end
function M.run()
    local reg=vim.tbl_keys(vim.region(0,'v','.','',true))
    local beg,fin=vim.fn.min(reg),vim.fn.max(reg)+1
    if vim.v.count>0 then fin=fin+vim.v.count-1 end
    M.comment_lines(beg,fin)
end
return M
