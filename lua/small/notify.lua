--Inspired by https://github.com/j-hui/fidget.nvim
local M={conf={
    style={
        TRACE='Comment',
        DEBUG='Debug',
        INFO='Normal',
        WARN='WarningMsg',
        ERROR='ErrorMsg',
        OFF={hl='Error',winblend=0},
    },
    fallback_notify=vim.notify,
    historysize=100,
    timeout=3000,
}}
M.history={}
M.notifs={}
function M.add_to_history(info)
    table.insert(M.history,info)
    if #M.history>M.conf.historysize then table.remove(M.history,1) end
end
function M.open_history()
    local buf=vim.api.nvim_create_buf(false,true)
    vim.api.nvim_buf_set_lines(buf,0,-1,false,vim.split(table.concat(M.history,'\n\n'),'\n'))
    vim.cmd.vsplit()
    vim.api.nvim_set_current_buf(buf)
end
function M.override_notify()
    rawset(vim,'notify',M.notify)
end
M.update=function()
    local i=0
    for k,v in vim.spairs(M.notifs) do
        if v.dispand then
            if vim.api.nvim_get_current_buf()==v.buf then
                vim.api.nvim_create_autocmd('WinLeave',{buffer=v.buf,callback=vim.schedule_wrap(M.update),once=true})
            else
                if v.buf then
                    if not pcall(vim.api.nvim_buf_delete,v.buf,{force=true}) then
                        vim.defer_fn(M.update,10) return
                    end
                end
                M.notifs[k]=nil
            end
            goto continue
        end
        local text=vim.split(v.msg,'\n')
        local level
        for name,lvl in pairs(vim.log.levels) do
            if v.level==lvl then
                level=name
                break
            end
        end
        local width=math.max(unpack(vim.tbl_map(vim.api.nvim_strwidth,text)))
        local winopt={
            height=#text,
            width=width,
            relative='editor',
            col=vim.o.columns-width,
            row=i,
        }
        i=i+#text
        if not v.hasbuf then
            v.buf=v.buf or vim.api.nvim_create_buf(false,true)
            if not pcall(vim.api.nvim_buf_set_lines,v.buf,0,-1,false,text) then
                vim.defer_fn(M.update,10) return
            end
            v.hasbuf=true
        end
        if not v.win or not vim.api.nvim_win_is_valid(v.win) then
            local style=M.conf.style[level] or {hl='Normal'}
            if type(style)=='string' then style={hl=style} end
            local s,win=pcall(vim.api.nvim_open_win,v.buf,false,vim.tbl_extend('force',{style='minimal',noautocmd=true},winopt))
            if not s then
                vim.defer_fn(M.update,10) return
            end
            v.win=win
            vim.wo[v.win].winblend=style.winblend or 100
            vim.wo[v.win].winhl='Normal:'..style.hl
        else
            vim.api.nvim_win_set_config(v.win,winopt)
        end
        ::continue::
    end
end
function M.notify(msg,level,opts)
    M.add_to_history(msg)
    local time=vim.uv.hrtime()
    while M.notifs[time] do time=time+1 end
    M.notifs[time]={msg=msg,level=level,opts=opts}
    vim.defer_fn(function ()
        if M.notifs[time] then
            M.notifs[time].dispand=true
            M.update()
        end
    end,(opts or {}).timeout or M.conf.timeout)
    M.update()
end
function M.dismiss()
    for _,v in pairs(M.notifs) do
        v.dispand=true
    end
    M.update()
end
if vim.dev then
    M.notify('a',vim.log.levels.TRACE)
    vim.defer_fn(function ()
        M.notify('a',vim.log.levels.DEBUG)
        M.notify('ab',vim.log.levels.INFO)
        M.notify('a\nb',vim.log.levels.WARN)
        M.notify('a\nbc',vim.log.levels.ERROR)
        M.notify('ab\nc',vim.log.levels.OFF)
    end,500)
    vim.keymap.set('n','\\n',M.open_history)
end
return M
