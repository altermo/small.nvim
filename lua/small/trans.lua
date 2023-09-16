local M={from='sv',to='en'}
function M.cword()
    local linenr,col=unpack(vim.api.nvim_win_get_cursor(0))
    local line=vim.api.nvim_get_current_line()
    local fin=(vim.regex('[^[:keyword:]]'):match_str(line:sub(col+1)) or #line-col)+col+1
    local beg=col+1-(vim.regex('[^[:keyword:]]'):match_str(line:sub(1,col+1):reverse()) or col+1)
    local word=vim.system({'trans',('%s:%s'):format(M.from,M.to),'-b','--',line:sub(beg+1,fin-1)}):wait().stdout:sub(1,-2)
    vim.api.nvim_buf_set_lines(0,linenr-1,linenr,false,{line:sub(1,beg)..word..line:sub(fin)})
end
return M
