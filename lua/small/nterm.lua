local M={}
---@param cmd? string
---@param smart_quit_nvim? boolean if is the only buffer then quit neovim when exit
function M.run(cmd,smart_quit_nvim)
    cmd=cmd or vim.o.shell
    vim.cmd.enew()
    local buf=vim.api.nvim_get_current_buf()
    vim.fn.termopen(cmd,{on_exit=function (_,_,_)
        if smart_quit_nvim and #vim.fn.getbufinfo()==1 and vim.api.nvim_get_current_buf()==buf then vim.cmd.quitall() end
        pcall(vim.cmd.bdelete,{buf,bang=true})
    end})
    vim.api.nvim_set_option_value('bufhidden','wipe',{buf=buf})
    vim.cmd.startinsert()
end
return M
