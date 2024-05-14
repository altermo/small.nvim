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
function M.get_pid_table()
    -- Dont use vim.api.nvim_get_proc_children, see https://github.com/neovim/neovim/issues/28741
    if vim.fn.has'unix' then
        return M.get_pid_table_unix()
    end
    error(('Not supported for `%s` operating system'):format(vim.uv.os_uname().sysname))
end
function M.get_pid_table_unix()
    local pid_table={[0]={}}
    for i in vim.fs.dir('/proc') do
        if tonumber(i) then
            pid_table[tonumber(i)]={}
        end
    end
    for pid,_ in pairs(pid_table) do
        if pid~=0 then
            local f=assert(io.open('/proc/'..pid..'/stat', 'r'))
            local stat=f:read('*l')
            f:close()
            local ppid=tonumber(stat:match('^%d+ %(.-%) [^ ] (%d+)'))
            table.insert(pid_table[ppid],pid)
        end
    end
    return pid_table
end
function M.update(buf)
    local pid_table=M.get_pid_table()
    for _,subpid in pairs(pid_table) do
        table.sort(subpid)
    end
    local function f(table,level)
        for _,subpid in ipairs(table) do
            vim.api.nvim_buf_set_lines(buf,-1,-1,false,{(' '):rep(level)..tostring(subpid)})
            f(pid_table[subpid],level+2)
        end
    end
    f(pid_table[0],0)
    vim.api.nvim_buf_set_lines(buf,0,1,false,{})
end
function M.open()
    local buf=M.create_buffer()
    vim.cmd.vsplit()
    vim.api.nvim_set_current_buf(buf)
    M.update(buf)
end
return M
