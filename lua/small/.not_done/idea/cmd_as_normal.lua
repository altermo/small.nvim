local M={}
function M.wrap(fn)
    return function()
        local cursor=vim.fn.getcmdpos()-1
        local line=vim.fn.getcmdline()
        local buf=vim.api.nvim_create_buf(true,true)
        local win=vim.api.nvim_open_win(buf,false,{relative='win',row=6,col=6,width=30,height=5})
        vim.api.nvim_set_option_value('filetype','vim',{buf=buf})
        vim.api.nvim_buf_set_lines(buf,0,-1,false,{line})
        local ret
        local col
        vim.api.nvim_win_call(win,function()
            vim.api.nvim_win_set_cursor(0,{1,cursor})
            vim.cmd.startinsert()
            ret={pcall(fn)}
            vim.cmd.stopinsert()
            col=vim.api.nvim_win_get_cursor(win)[2]
        end)
        vim.api.nvim_win_close(win,true)
        vim.api.nvim_buf_delete(buf,{})
        if not ret[1] then error(ret[2]) end
        vim.api.nvim_feedkeys(vim.keycode('<home>'..('<right>'):rep(col)),'n',true)
    end
end
function M.map(lhs,rhs)
    vim.keymap.set('c',lhs,M.wrap(rhs))
end
M.map(';',function()
    require'tabout'.tabout()
end)
return M
