local dap=require'dap'
local _=require'osv'
local M={}
function M.start_nvim()
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
function M.start()
    M.prevbuf=M.buf
    M.buf=vim.api.nvim_create_buf(false,true)
    vim.bo[M.buf].bufhidden='wipe'
    if M.prevbuf and vim.api.nvim_buf_is_valid(M.prevbuf) then
        for _,w in ipairs(vim.fn.win_findbuf(M.prevbuf)) do
            vim.api.nvim_win_set_buf(w,M.buf)
        end
    else
        vim.api.nvim_open_win(M.buf,false,{split='right'})
    end
    local server_path=M.start_nvim()
    vim.api.nvim_buf_call(M.buf,function ()
        vim.cmd.term(table.concat({'nvim','--remote-ui','--server',server_path},' '))
    end)
end
return M
