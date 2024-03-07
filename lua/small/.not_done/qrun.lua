local M={}
function M.start_neovim(noconfig)
    local cmd={'nvim','--headless','--embed'}
    if noconfig then
        table.insert(cmd,'--n')
    end
    return vim.fn.jobstart(cmd,{rpc=true})
end
function M.open_neovim_in_buf(rpc)
    local server_path=vim.rpcrequest(rpc,'nvim_get_vvar','servername')
    vim.cmd.term(table.concat({'nvim','--remote-ui','--server',server_path},' '))
end
return M

