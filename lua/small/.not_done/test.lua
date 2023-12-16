local M={}
function M.test(data)
    if M.win and vim.api.nvim_win_is_valid(M.win) then vim.api.nvim_win_close(M.win,true) end
    if M.buf and vim.api.nvim_buf_is_valid(M.buf) then vim.api.nvim_buf_delete(M.buf,{force=true}) end
    M.buf=vim.api.nvim_create_buf(true,true)
    local id
    vim.api.nvim_buf_call(M.buf,function()
        id=vim.fn.termopen('nvim')
    end)
    vim.fn.chansend(id,data)
end
if vim.dev then
    M.test(':q')
end
return M
