local M={model='deepseek-coder'}
function M.ask(text,opt)
    local out=''
    local function update() vim.api.nvim_buf_set_lines(opt.buf,0,-1,false,vim.split(out,'\n')) end
    update()
    return vim.system({'ollama','run',M.model,text},{stdout=function (err,data)
        if err then error(err) end
        if data then out=out..data end
        vim.schedule(update)
    end},function (data)
            if data.code~=0 then
                if data then out=out..data.stderr end
            end
            vim.schedule(update)
        end)
end
function M.open(_)
    if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
        M.buf=vim.api.nvim_create_buf(true,true)
        vim.api.nvim_buf_set_name(M.buf,'ollama chat')
        vim.o.bufhidden='wipe'
        vim.api.nvim_create_autocmd('BufHidden',{buffer=M.buf,callback=function ()
            if M.proc then M.proc:kill(1) end
        end})
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
