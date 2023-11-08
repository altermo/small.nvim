local I={}
local M={I=I}
function I.clear() return '\x1b[2J\x1b[H' end
function I.origo() return '\x1b[H' end
function M.open_mode(on_input,on_redraw)
    local win=vim.api.nvim_get_current_win()
    local scrollback=10
    local buf=vim.api.nvim_create_buf(true,true)
    vim.bo[buf].bufhidden='wipe'
    local chan=vim.api.nvim_open_term(buf,{on_input=on_input})
    local au
    local redraw=function ()
        if not vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_del_autocmd(au) return end
        vim.api.nvim_chan_send(chan,('SCROLLBACK_LINE\n\r'):rep(scrollback))
        vim.api.nvim_chan_send(chan,('\n\r'):rep(vim.api.nvim_win_get_height(win)-1))
        local pos=vim.api.nvim_win_get_cursor(win)
        vim.api.nvim_win_call(win,function ()
            vim.api.nvim_feedkeys('G','n',false)
            vim.api.nvim_win_set_cursor(0,pos)
            --vim.api.nvim_chan_send(chan,I.origo())
        end)
        if on_redraw then on_redraw() end
    end
    au=vim.api.nvim_create_autocmd('WinResized',{callback=redraw})
    vim.bo[buf].scrollback=scrollback
    vim.api.nvim_set_current_buf(buf)
    vim.wo[win].scrolloff=0
    redraw()
    return chan
end
function M.clear(chan)
    vim.api.nvim_chan_send(chan,I.clear())
end
if vim.dev then
    vim.cmd.vsplit()
    local chan=M.open_mode()
    M.clear(chan)
end
return M
