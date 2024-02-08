local M={}
function M.ask(text,opt)
    local out=''
    local function update() vim.api.nvim_buf_set_lines(opt.buf,0,-1,false,vim.split(out,'\n')) end
    update()
    return vim.system({'chat',text},{stdout=function (err,data)
        if err then error(err) end
        if data then out=out..data end
        vim.schedule(function ()
            if not vim.api.nvim_buf_is_valid(opt.buf) then M.proc:kill(1) end
            pcall(update)
        end)
    end})
end
function M.open(_)
    if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
        M.buf=vim.api.nvim_create_buf(true,true)
        vim.api.nvim_buf_set_name(M.buf,'chat')
        vim.api.nvim_create_autocmd('BufWipeout',{buffer=M.buf,callback=function ()
            if M.proc then M.proc:kill(1) end
        end})
        vim.bo[M.buf].bufhidden='wipe'
    end
    if #vim.fn.win_findbuf(M.buf)==0 then
        vim.cmd.split()
        vim.api.nvim_win_set_buf(0,M.buf)
    end
    return {buf=M.buf}
end
function M.run()
    vim.ui.input({prompt='chat> '},function (inp)
        if inp==nil or vim.trim(inp)=='' then return end
        if M.proc then M.proc:kill(1) end
        M.proc=M.ask(inp,M.open(inp))
    end)
end
return M
