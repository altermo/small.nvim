local M={}
function M.wrap(key)
    return function()
        local cursor=vim.fn.getcmdpos()-1
        local line=vim.fn.getcmdline()
        local buf=vim.api.nvim_create_buf(true,true)
        local win=vim.api.nvim_open_win(buf,false,{relative='win',row=6,col=6,width=50,height=10,hide=false})

        vim.api.nvim_set_option_value('filetype','vim',{buf=buf})
        vim.api.nvim_buf_set_lines(buf,0,-1,false,{line})
        vim.api.nvim_win_set_cursor(win,{1,cursor})
        vim.api.nvim_set_current_win(win)

        vim.api.nvim_feedkeys(vim.keycode'<C-\\><C-n>i','n',false)
        vim.api.nvim_feedkeys(vim.keycode(key),'m',false)
        vim.api.nvim_feedkeys(vim.keycode'<C-\\><C-n>:','n',false)
        vim.schedule(function()
            local col=vim.api.nvim_win_get_cursor(win)[2]+1
            vim.api.nvim_feedkeys(vim.api.nvim_buf_get_lines(buf,0,-1,false)[1],'n',false)
            vim.api.nvim_feedkeys(vim.keycode('<home>'..('<right>'):rep(col)),'n',false)
            vim.api.nvim_win_close(win,true)
            vim.api.nvim_buf_delete(buf,{})
        end)
    end
end
function M.map(key)
    vim.keymap.set('c',key,M.wrap(key))
end
return M
