--TODO: make sure it works on windows
local M={}
M.proc_to_icon={} --TODO
function M.create_buffer()
    if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
        return M.buf
    end
    local buf=vim.api.nvim_create_buf(true,true)
    vim.bo[buf].bufhidden='wipe'
    pcall(vim.api.nvim_buf_set_name,buf,'top')
    M.buf=buf
    return buf
end
function M.get_pid_tree(pid)
    local ret={}
    -- Dont use vim.api.nvim_get_proc_children, see https://github.com/neovim/neovim/issues/28741
    for _,p in vim.spairs(vim.api.nvim_get_proc_children(pid)) do
        ret[p]=M.get_pid_tree(p)
    end
    return ret
end
function M.update(buf)
    local get_pid_tree=M.get_pid_tree(1)
    local function f(tree,level)
        for pid,subtree in vim.spairs(tree) do
            vim.api.nvim_buf_set_lines(buf,-1,-1,false,{(' '):rep(level)..tostring(pid)})
            f(subtree,level+2)
        end
    end
    f({[1]=get_pid_tree},0)
    vim.api.nvim_buf_set_lines(buf,0,1,false,{})
end
function M.open()
    local buf=M.create_buffer()
    vim.cmd.vsplit()
    vim.api.nvim_set_current_buf(buf)
    M.update(buf)
end
return M
