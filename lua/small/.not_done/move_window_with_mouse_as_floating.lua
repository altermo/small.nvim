local M={}
--TODO: check out nvim_input_mouse()
function M.is_floating(win)
    return vim.api.nvim_win_get_config(win).relative~=''
end
function M.make_floating(win)
    local width=vim.api.nvim_win_get_width(win)
    local height=vim.api.nvim_win_get_height(win)
    local row,col=unpack(vim.api.nvim_win_get_position(win))
    local lbuf=vim.api.nvim_win_get_buf(win)
    local buf=vim.api.nvim_create_buf(false,true)
    vim.api.nvim_set_option_value('bufhidden','wipe',{buf=buf})
    vim.api.nvim_win_set_buf(win,buf)
    return vim.api.nvim_open_win(lbuf,true,{
        relative='editor',
        width=width,
        height=height,
        row=row,
        col=col,
    })
end
function M.move_floating_window(win)
    win=win or 0
    if not M.is_floating(win) then
        win=M.make_floating(win)
    end
    M.start_act_floating_window(win)
    local mousepos=vim.fn.getmousepos()
    local row=mousepos.screenrow-M.mousepos.winrow
    local col=mousepos.screencol-M.mousepos.wincol
    vim.api.nvim_win_set_config(win,{row=row,col=col,relative='editor'})
end
function M.resize_floating_window(win)
    win=win or 0
    if not M.is_floating(win) then
        win=M.make_floating(win)
    end
    M.start_act_floating_window(win)
    local mousepos=vim.fn.getmousepos()
    local rowdiff=M.mousepos.winrow-mousepos.winrow
    local coldiff=M.mousepos.wincol-mousepos.wincol
    vim.api.nvim_win_set_config(win,{height=M.win.height-rowdiff,width=M.win.width-coldiff})
end
function M.stop_act_floating_window()
    M.mousepos=nil
end
function M.start_act_floating_window(win)
    if not M.mousepos then
        M.mousepos=vim.fn.getmousepos()
        M.win=vim.api.nvim_win_get_config(win)
    end
end
function M.setup()
    vim.keymap.set('n','<LeftDrag>',M.move_floating_window)
    vim.keymap.set('n','<LeftRelease>',M.stop_act_floating_window)
    vim.keymap.set('n','<RightDrag>',M.resize_floating_window)
    vim.keymap.set('n','<RightRelease>',M.stop_act_floating_window)
end
M.setup()
return M
