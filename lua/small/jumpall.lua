---Rewrite of https://github.com/mizlan/longbow.nvim
local M={
    ns=vim.api.nvim_create_namespace('small_jumpall'),
    conf={labels='abcdefghijklmnopqrstuvwxyz0123456789'},
}
---@param keys string
---@return string
function M.generate_sequence(keys,_n)
    _n=_n or 1
    if _n>#keys then return keys:sub(1,1) end
    local char=keys:sub(_n,_n)
    local ret=char
    for i in keys:sub(_n+1):gmatch'.' do
        ret=ret..char..i
    end
    return ret..M.generate_sequence(keys,_n+1)
end
function M.run(opts)
    opts=vim.tbl_extend('force',M.conf,opts or {})
    local s,err=pcall(function()
        vim.api.nvim_win_add_ns(0,M.ns)
        local labels=M.generate_sequence(opts.labels)
        local win=vim.api.nvim_get_current_win()
        local lcol=1
        local plcol=1
        local botline=vim.fn.getwininfo(win)[1].botline
        local topline=vim.fn.getwininfo(win)[1].topline
        local pos={}
        for row=topline-1,botline-1 do
            local line=vim.fn.getline(row+1)
            local indent=line:find('[^%s]')
            if not indent then
                lcol=lcol+1
                indent=#line+2
            end
            pos[row]={off=indent-1}
            for col=indent-1,vim.api.nvim_strwidth(line) do
                vim.api.nvim_buf_set_extmark(0,M.ns,row,col,{
                    virt_text={{labels:sub(lcol,lcol)}},
                    virt_text_pos='overlay',
                    hl_mode='combine',
                })
                lcol=lcol+1
                if lcol>#labels then
                    vim.api.nvim_buf_set_extmark(0,M.ns,row,col+1,{
                        hl_group='Comment',
                        end_row=botline-1
                    })
                    pos[row].l=labels:sub(plcol,lcol)
                    goto END
                end
            end
            lcol=lcol-1
            pos[row].l=labels:sub(plcol,lcol)
            plcol=lcol
        end
        ::END::
        vim.cmd.redraw()
        local char=vim.fn.getcharstr()
        if not opts.labels:find(char,1,true) then return end
        local char2=vim.fn.getcharstr()
        if not opts.labels:find(char2,1,true) then return end
        for row,data in pairs(pos) do
            local idx=data.l:find(char..char2,1,true)
            if idx then
                vim.api.nvim_win_set_cursor(0,{row+1,idx-1+data.off})
                return
            end
        end
    end)
    vim.api.nvim_buf_clear_namespace(0,M.ns,0,-1)
    vim.api.nvim_win_remove_ns(0,M.ns)
    if not s then error(err) end
end
if vim.dev then
    M.run()
end
return M
