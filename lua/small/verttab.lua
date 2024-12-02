local M={ns=vim.api.nvim_create_namespace('SmallVertTab')}
local function refresh()
    if not M.opened then
        if M.win then
            pcall(vim.api.nvim_win_close,M.win,true)
            M.win=nil
        end
        return
    end
    local old_win=M.win
    M.win=vim.api.nvim_open_win(M.buf,false,{
        relative='editor',
        width=1,
        height=vim.o.lines,
        row=0,
        col=vim.o.columns-1,
        style='minimal',
        focusable=false,
        noautocmd=true,
    })
    if old_win then
        vim.api.nvim_win_close(old_win,true)
    end
    vim.wo[M.win].winhighlight='Normal:Normal'
    vim.api.nvim_buf_set_lines(M.buf,0,-1,false,{})
    for _,info in ipairs(vim.fn.gettabinfo()) do
        vim.api.nvim_buf_set_lines(M.buf,info.tabnr-1,info.tabnr,false,{tostring(info.tabnr)})
        if info.tabnr==vim.fn.tabpagenr() then
            vim.api.nvim_buf_set_extmark(M.buf,M.ns,info.tabnr-1,0,{
                hl_group='ErrorMsg',
                end_col=1,
            })
        end
    end
end
function M.setup()
    M.buf=vim.api.nvim_create_buf(false,true)
    local last_tab=vim.fn.tabpagenr()
    local timeout
    ---@diagnostic disable-next-line: redundant-parameter
    vim.ui_attach(M.ns,{ext_tabline=true},function (event,curtab)
        pcall(function ()
            if event~='tabline_update' then return end
            --if #vim.fn.gettabinfo()==1 and M.opened then
            --    M.opened=false
            --    refresh()
            --    if timeout then timeout:close() timeout=nil end
            if curtab~=last_tab then
                last_tab=curtab
                M.opened=true
                refresh()
                if timeout then timeout:close() timeout=nil end
                timeout=vim.defer_fn(function ()
                    timeout=nil
                    M.opened=false
                    refresh()
                end,1000)
            else
                refresh()
            end
        end)
    end)
end
return M
