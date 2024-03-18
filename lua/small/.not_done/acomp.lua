local M={}
M.completionlist={}
function M.get_pos()
    if vim.fn.mode()=='c' then
        return vim.o.lines-2,vim.fn.getcmdpos()
    end
    local info=vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
    return info.winrow+vim.fn.winline()-1,info.wincol+vim.fn.wincol()-2
end
function M.is_open()
    return vim.api.nvim_win_get_config(M.win).hide==false
end
function M.close()
    if not M.is_open() then return end
    vim.api.nvim_win_set_config(M.win,{hide=true})
end
function M.update()
    if M.is_open() then M.close() end
    vim.api.nvim_win_set_config(M.win,{hide=false})
    local row,col=M.get_pos()
    vim.api.nvim_win_set_config(M.win,{
        relative='editor',
        row=row,
        col=col,
    })
end
function M.setup()
    M.group=vim.api.nvim_create_augroup('small_acomp',{})
    M.buf=vim.api.nvim_create_buf(false,true)
    M.win=vim.api.nvim_open_win(M.buf,false,{
        hide=true,
        relative='editor',
        col=1,row=1,height=1,width=1,
        style='minimal',
    })
    vim.keymap.set({'i','c'},'§',function ()
        M.update()
    end)
    vim.api.nvim_create_autocmd({'InsertLeave','CmdlineLeave'},{
        callback=M.close,
        group=M.augroup,
    })
end
if vim.dev then
    M.setup()
end
return M
