local M={conf={make_non_float_float_on_drag=false}}
---@param win? number
---@return boolean
function M.is_floating(win)
    return vim.api.nvim_win_get_config(win or 0).relative~=''
end
---@param win? number
---@param opt? table
---@return nil|number
function M.make_floating(win,opt)
    win=win or 0
    local row,col=unpack(vim.api.nvim_win_get_position(win))
    opt=vim.tbl_extend('force',{
        relative='editor',
        row=row,
        col=col,
        width=vim.api.nvim_win_get_width(win),
        height=vim.api.nvim_win_get_height(win)
    },opt or {})
    vim.api.nvim_win_set_config(0,opt)
end
---@param win? number
function M.move_floating_window(win)
    win=win or 0
    if not M.is_floating(win) then
        if not M.conf.make_non_float_float_on_drag then return end
        M.make_floating(win)
    end
    if not M.inst then M.initlize(win) end
    local inst=M.inst
    local mouse=vim.fn.getmousepos()
    local rowdiff=inst.mouse.screenrow-mouse.screenrow
    local coldiff=inst.mouse.screencol-mouse.screencol
    vim.api.nvim_win_set_config(win,{row=inst.winpos[1]-rowdiff,col=inst.winpos[2]-coldiff,relative='editor'})
end
---@param win? number
function M.resize_floating_window(win)
    win=win or 0
    if not M.is_floating(win) then
        if not M.conf.make_non_float_float_on_drag then return end
        M.make_floating(win)
    end
    if not M.inst then M.initlize(win) end
    local inst=M.inst
    local mouse=vim.fn.getmousepos()
    local rowdiff=inst.mouse.screenrow-mouse.screenrow
    local coldiff=inst.mouse.screencol-mouse.screencol
    vim.api.nvim_win_set_config(win,{height=math.max(1,inst.win.height-rowdiff),width=math.max(1,inst.win.width-coldiff)})
end
---@param win? number
function M.initlize(win)
    M.inst={
        mouse=vim.fn.getmousepos(),
        win=vim.api.nvim_win_get_config(win or 0),
        winpos=vim.api.nvim_win_get_position(win or 0),
    }
end
function M.deinitilize() M.inst=nil end
function M.setup()
    vim.keymap.set('n','<C-LeftMouse>','')
    vim.keymap.set('n','<C-RightMouse>','')
    vim.keymap.set('n','<C-LeftDrag>',M.move_floating_window)
    vim.keymap.set('n','<C-LeftRelease>',M.deinitilize)
    vim.keymap.set('n','<C-RightDrag>',M.resize_floating_window)
    vim.keymap.set('n','<C-RightRelease>',M.deinitilize)
end
if vim.dev then
    vim.cmd.split()
    M.make_floating()
    M.setup()
end
return M
