local M={}
function M.ask(text,opt)
    local out=''
    local function update() vim.api.nvim_buf_set_lines(opt.buf,0,-1,false,vim.split(out,'\n')) end
    update()
    return vim.system({'tgpt','-q',text},{stdout=function (err,data)
        if err then error(err) end
        if data then out=out..data end
        vim.schedule(update)
    end})
end
function M.open(_)
    if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
        M.buf=vim.api.nvim_create_buf(true,true)
        vim.api.nvim_buf_set_name(M.buf,'tgpt chat')
    end
    if not M.win or not vim.api.nvim_win_is_valid(M.win) or vim.api.nvim_win_get_buf(M.win)~=M.buf then
        vim.cmd.split()
        M.win=vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(M.win,M.buf)
    end
    return {buf=M.buf}
end
function M.run()
    vim.ui.input({prompt='chat> '},function (inp)
        if inp==nil or vim.trim(inp)=='' then return end
        M.ask(inp,M.open(inp))
    end)
end
return M
