local M={}
---@param cmd? string
---@param smart_quit_nvim? boolean if is the only buffer then quit neovim when exit
---@param smart_quit_term? boolean if the only thing running in the terminal is a shell then quit the terminal
function M.run(cmd,smart_quit_nvim,smart_quit_term)
    cmd=cmd or vim.o.shell
    vim.cmd.enew()
    local buf=vim.api.nvim_get_current_buf()
    local term=vim.fn.termopen(cmd,{on_exit=function (_,_,_)
        if smart_quit_nvim and #vim.tbl_filter(function (b)
            return vim.bo[b].buftype~='nofile'
        end,vim.api.nvim_list_bufs())==1 and vim.api.nvim_get_current_buf()==buf and buf==1
        then vim.cmd.quitall() end
        pcall(vim.cmd.bdelete,{buf,bang=true})
    end})
    vim.cmd.startinsert()
    if not smart_quit_term then return end
    vim.api.nvim_create_autocmd('BufHidden',{buffer=buf,callback=function ()
        local pid=vim.fn.jobpid(term)
        if vim.fs.basename(vim.o.shell)~=vim.api.nvim_get_proc(pid).name then return end
        local children=vim.api.nvim_get_proc_children(pid)
        if #children==1 and vim.api.nvim_get_proc(children[1]).name==vim.fs.basename(vim.o.shell) then
            children=vim.api.nvim_get_proc_children(children[1])
        end
        if not vim.tbl_isempty(children) then return end
        vim.schedule_wrap(print)('Terminal '..vim.fs.basename(vim.fn.bufname(buf))..' closed')
        vim.schedule_wrap(vim.cmd.bwipeout){buf,bang=true}
    end})
end
return M
