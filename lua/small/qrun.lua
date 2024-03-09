local M={}
function M.start_neovim(noconfig)
    local cmd={'nvim','--headless','--embed','-n'}
    if noconfig then
        table.insert(cmd,'--clean')
    end
    return vim.fn.jobstart(cmd,{rpc=true})
end
function M.open_neovim_in_buf(rpc)
    local server_path=vim.rpcrequest(rpc,'nvim_get_vvar','servername')
    vim.cmd.term(table.concat({'nvim','--remote-ui','--server',server_path},' '))
end
function M.getfile()
    local dir=vim.fs.find({'.git'},{upward=true})[1]
    if not dir then return end
    dir=vim.fs.dirname(dir)
    if vim.fn.filereadable(vim.fs.joinpath(dir,'dapnvim.lua'))==0 then return end
    return vim.fs.joinpath(dir,'dapnvim.lua')
end
function M.run()
    local file=M.getfile()
    local prevbuf=M.buf
    M.buf=vim.api.nvim_create_buf(false,true)
    vim.bo[M.buf].bufhidden='wipe'
    if prevbuf and vim.api.nvim_buf_is_valid(prevbuf) then
        for _,w in ipairs(vim.fn.win_findbuf(prevbuf)) do
            vim.api.nvim_win_set_buf(w,M.buf)
        end
    else
        vim.cmd.vsplit()
        vim.api.nvim_set_current_buf(M.buf)
    end
    if M.rpc then
        vim.fn.jobstop(M.rpc)
    end
    if file then
        M.rpc=M.start_neovim(vim.fn.readfile(file)[1]:find('noconf'))
    else
        M.rpc=M.start_neovim()
    end
    vim.api.nvim_buf_call(M.buf,function ()
        M.open_neovim_in_buf(M.rpc)
    end)
    if not file then return end
    vim.wait(100)
    vim.rpcnotify(M.rpc,'nvim_exec_lua',[[
        local file=...
        loadfile(file)()
        ]],{file})
end
return M
