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
function M.replace_statusline()
    if vim.o.laststatus~=3  then
        error('\nWill not work if laststatus is not 3\nNote: if you change laststatus while it is active then it may break')
        return
    end
    vim.o.laststatus=3
    local buf=vim.api.nvim_create_buf(false,true)
    local win=vim.api.nvim_open_win(buf,false,{
        relative='win',
        row=vim.o.lines-1,col=1,
        width=vim.o.columns,height=1,
        style='minimal'
    })
    local update=vim.schedule_wrap(function ()
        if vim.o.statusline==' ' then return end
        if vim.api.nvim_get_current_win()==win then return end
        local s,maxwidth=pcall(vim.api.nvim_win_get_width,win)
        if not s then maxwidth=vim.o.columns end
        vim.api.nvim_buf_set_lines(buf,0,-1,false,{vim.api.nvim_eval_statusline(vim.o.statusline,{maxwidth=maxwidth}).str})
        local col=0
        for _,v in ipairs(M.get_statusline({maxwidth=maxwidth})) do
            vim.highlight.range(buf,vim.api.nvim_create_namespace(''),v[2],{0,col},{0,col+#v[1]})
            col=col+#v[1]
        end
        vim.o.statusline=' '
        for _,v in ipairs(vim.api.nvim_list_wins()) do
            vim.wo[v].statusline=' '
        end
    end)
    vim.api.nvim_create_autocmd('OptionSet',{pattern='statusline',callback=update})
    update()
end
if vim.dev then
    vim.o.laststatus=3
    M.replace_statusline()
end
return M
