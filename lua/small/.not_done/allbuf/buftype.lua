local M={}
---@param buf number
function M.buf_set_noenter(buf)
    vim.api.nvim_create_autocmd('WinEnter',{buffer=buf,callback=function ()
        local win=vim.api.nvim_get_current_win()
        vim.cmd.wincmd'p'
        local lastwin=vim.api.nvim_get_current_win()
        vim.cmd.wincmd'p'
    end})
end
if vim.dev then
    vim.cmd.split()
    local buf=vim.api.nvim_create_buf(true,true)
    vim.bo[buf].bufhidden='wipe'
    vim.api.nvim_set_current_buf(buf)
    M.buf_set_noenter(buf)
end
return M
