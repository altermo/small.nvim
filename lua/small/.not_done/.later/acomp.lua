local M={}
M.completionlist={}
function M.get_pos()
    if vim.fn.mode()=='c' then
        return {
            relative='editor',
        }
    end
    return {
        relative='win',
        win=vim.api.nvim_get_current_win(),
        col=vim.fn.wincol()-2,
        row=vim.fn.winline(),
    }
end
function M.is_open()
    return vim.api.nvim_win_get_config(M.win).hide==false
end
function M.close()
    if not M.is_open() then return end
    vim.api.nvim_win_set_config(M.win,{hide=true})
end
function M.open()
    if M.is_open() then return end
    vim.api.nvim_win_set_config(M.win,{hide=false})
    vim.api.nvim_win_set_config(M.win,M.get_pos())
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
        M.open()
    end)
    vim.api.nvim_create_autocmd('InsertLeave',{
        callback=M.close,
        group=M.augroup,
    })
end
if vim.dev then
    M.setup()
end
return M
