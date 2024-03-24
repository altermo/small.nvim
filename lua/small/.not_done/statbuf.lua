local M={group=vim.api.nvim_create_augroup('small_statbuf',{})}
function M.update(win)
    local conf=vim.api.nvim_win_get_config(win)
    local lwin=vim.w[win].small_statbuf_win
    if not lwin then return end
    local buf=vim.api.nvim_win_get_buf(lwin)
    vim.api.nvim_win_set_config(lwin,{
        relative='win',win=win,
        row=conf.height,
        col=1,height=1,
        width=conf.width,
    })
    local s=vim.api.nvim_eval_statusline(vim.wo[win].statusline or vim.o.statusline,{highlights=true,maxwidth=conf.width})
    vim.api.nvim_buf_set_lines(buf,0,-1,false,{s.str})
    local col=0
    for k,v in ipairs(s.highlights) do
        local next=s.highlights[k+1] or {start=#s.str}
        vim.highlight.range(buf,vim.api.nvim_create_namespace(''),v.group,{0,col},{0,col+next.start-v.start})
        col=col+#s.str:sub(v.start+1,next.start)
    end
end
function M.win_remove_status(win)
    local lwin=vim.w[win].small_statbuf_win
    if not lwin then return end
    vim.api.nvim_win_close(lwin,true)
end
function M.win_create_status(win)
    local conf=vim.api.nvim_win_get_config(win)
    if conf.relative~='' then return true end
    local buf=vim.api.nvim_create_buf(false,true)
    vim.bo[buf].bufhidden='wipe'
    vim.w[win].small_statbuf_win=vim.api.nvim_open_win(buf,false,{
        relative='win',win=win,col=1,row=1,width=1,height=1,
        style='minimal',focusable=false,
    })
    vim.wo[vim.w[win].small_statbuf_win].winfixbuf=true
    M.update(win)
end
function M.setup()
    vim.api.nvim_create_autocmd('WinNew',{callback=function ()
        M.win_create_status(vim.api.nvim_get_current_win())
    end,group=M.group})
    vim.api.nvim_create_autocmd('WinResized',{callback=function ()
        for _,win in pairs(vim.api.nvim_list_wins()) do
            M.update(win)
        end
    end,group=M.group})
    vim.api.nvim_create_autocmd('WinClosed',{callback=function (ev)
        M.win_remove_status(tonumber(ev.file))
    end,group=M.group})
    vim.api.nvim_create_autocmd('OptionSet',{callback=function ()
        for _,win in pairs(vim.api.nvim_list_wins()) do
            M.update(win)
        end
    end,group=M.group,pattern='statusline',})
    for _,win in pairs(vim.api.nvim_list_wins()) do
        M.win_create_status(win)
    end
end
if vim.dev then
    vim.cmd.fclose{bang=true}
    M.setup()
end
return M
