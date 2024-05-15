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
        local pid=tonumber(i)
        if not pid then
            goto continue
        end
        pid_table[pid]={}
        ::continue::
    end
    for pid,_ in pairs(pid_table) do
        if pid==0 then
            goto continue
        end
        local f=io.open('/proc/'..pid..'/stat', 'r')
        if not f then
            pid_table[pid]=nil
            goto continue
        end
        local stat=f:read('*l')
        f:close()
        local comm,ppid_str=stat:match('^%d+ %((.-)%) [^ ] (%d+)')
        table.insert(pid_table[tonumber(ppid_str)],pid)
        pid_table[pid].comm=comm
        ::continue::
    end
    return pid_table
end
function M.update(buf)
    local function l()
        local pid_table=M.get_pid_table()
        for _,subpid in pairs(pid_table) do
            table.sort(subpid)
        end
        local count=0
        local function f(table,level)
            for _,subpid in ipairs(table) do
                vim.api.nvim_buf_set_lines(buf,count,count+1,false,{(' '):rep(level)..tostring(subpid)..' '..tostring(pid_table[subpid].comm)})
                count=count+1
                f(pid_table[subpid],level+2)
            end
        end
        vim.bo[buf].modifiable=true
        f(pid_table[0],0)
        vim.api.nvim_buf_set_lines(buf,count,-1,false,{})
        vim.bo[buf].modifiable=false
        vim.defer_fn(l,1000)
    end
    l()
end
function M.open()
    local buf=M.create_buffer()
    vim.cmd.vsplit()
    vim.api.nvim_set_current_buf(buf)
    M.update(buf)
end
return M
