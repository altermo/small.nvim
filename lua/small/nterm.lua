local M={}
---@param cmd? string
---@param smart_quit_nvim? boolean if is the only buffer then quit neovim when exit
function M.run(cmd,smart_quit_nvim)
    cmd=cmd or vim.o.shell
    vim.cmd.enew()
    local buf=vim.api.nvim_get_current_buf()
    vim.fn.termopen(cmd,{on_exit=function (_,_,_)
        if smart_quit_nvim and #vim.tbl_filter(function (b)
            return vim.bo[b].buftype~='nofile'
        end,vim.api.nvim_list_bufs())==1 and vim.api.nvim_get_current_buf()==buf and buf==1
        then vim.cmd.quitall() end
        pcall(vim.cmd.bdelete,{buf,bang=true})
    end})
    vim.cmd.startinsert()
end
return M
