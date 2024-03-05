local M={}
---@param opt? vim.api.keyset.eval_statusline
---@param statusline? string
---@return string[][]
function M.get_statusline(opt,statusline)
    opt=vim.tbl_extend('force',{highlights=true},opt)
    local s=vim.api.nvim_eval_statusline(statusline or vim.o.statusline,opt)
    local str=s.str
    local high=s.highlights
    local out={}
    for k,v in ipairs(high) do
        local next=high[k+1] or {start=#str}
        table.insert(out,{str:sub(v.start+1,next.start),v.group})
    end
    return out
end
function M.update()
    local statusline=vim.o.statusline
    if vim.o.statusline==' ' then return end
    vim.o.statusline=' '
    for _,v in ipairs(vim.api.nvim_list_wins()) do
        vim.wo[v].statusline=' '
    end
    if vim.api.nvim_get_current_win()==M.win then return end
    local s,maxwidth=pcall(vim.api.nvim_win_get_width,M.win)
    if not s then maxwidth=vim.o.columns end
    vim.api.nvim_buf_set_lines(M.buf,0,-1,false,{vim.api.nvim_eval_statusline(statusline,{maxwidth=maxwidth}).str})
    local col=0
    for _,v in ipairs(M.get_statusline({maxwidth=maxwidth},statusline)) do
        vim.highlight.range(M.buf,vim.api.nvim_create_namespace(''),v[2],{0,col},{0,col+#v[1]})
        col=col+#v[1]
    end
end
function M.setup()
    M.buf=vim.api.nvim_create_buf(false,true)
    M.win=vim.api.nvim_open_win(M.buf,false,{
        relative='win',
        row=vim.o.lines-1,col=1,
        width=vim.o.columns,height=1,
        style='minimal'
    })
    M.au_group=vim.api.nvim_create_augroup('small_statusbuf',{})
    vim.api.nvim_create_autocmd('ModeChanged',{
        group=M.au_group,
        callback=function ()
            M.update()
            vim.cmd.redraw()
        end,
    })
    vim.api.nvim_create_autocmd('OptionSet',{
        group=M.au_group,
        pattern='statusline',
        callback=M.update,
    })
end
return M
