local dap=require'dap'
local _=require'osv'
local M={}
function M.start()
    if M.nvim then
        vim.fn.jobstop(M.nvim)
    end
    M.nvim=vim.fn.jobstart({'nvim','--headless','--embed'},{rpc=true})
    vim.rpcrequest(M.nvim,'nvim_exec_lua','require"osv".launch({port=8086})',{})
    vim.wait(100)
    dap.run({type='nlua',request='attach'})
    dap.listeners.after['setBreakpoints']['dapnvim']=function()
        vim.rpcnotify(M.nvim,'nvim_command','luafile '..vim.fn.expand'%:p')
    end
    return vim.rpcrequest(M.nvim,'nvim_get_vvar','servername')

end
function M.open()
    if M.buf and vim.api.nvim_buf_is_valid(M.buf) then return end
    M.buf=vim.api.nvim_create_buf(false,true)
    vim.bo[M.buf].bufhidden='wipe'
    vim.api.nvim_open_win(M.buf,false,{split='right'})
    local server_path=M.start()
    vim.api.nvim_buf_call(M.buf,function ()
        vim.cmd.term(table.concat({'nvim','--remote-ui','--server',server_path},' '))
    end)
    return true
end
function M.continue()
    if M.open() then return end
    dap.continue()
end
return M
