local M={}
function M.win_set_noenter(win,parentwin)
    vim.api.nvim_create_autocmd('WinEnter',{buffer=vim.api.nvim_win_get_buf(win),callback=function ()
        vim.cmd.wincmd'p'
        local lastwin=vim.api.nvim_get_current_win()
        vim.cmd.wincmd'p'
        if lastwin~=parentwin then
            vim.pprint(lastwin,parentwin)
            vim.api.nvim_set_current_win(parentwin)
        end
    end})
end
if vim.dev then
    local par=vim.api.nvim_get_current_win()
    vim.cmd.split()
    local buf=vim.api.nvim_create_buf(true,true)
    vim.bo[buf].bufhidden='wipe'
    vim.api.nvim_set_current_buf(buf)
    M.win_set_noenter(vim.api.nvim_get_current_win(),par)
end
return M
