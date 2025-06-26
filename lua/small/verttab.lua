local M={ns=vim.api.nvim_create_namespace('SmallVertTab')}
local function refresh()
    if not M.opened then
        if M.win then
            pcall(vim.api.nvim_win_close,M.win,true)
            M.win=nil
        end
        return
    end
    local maxwidth=1
    vim.api.nvim_buf_clear_namespace(M.buf,M.ns,0,-1)
    vim.api.nvim_buf_set_lines(M.buf,0,-1,false,{})
    local padding=1
    for _,tabid in ipairs(vim.api.nvim_list_tabpages()) do
        local win=vim.api.nvim_tabpage_get_win(tabid)
        local buf=vim.api.nvim_win_get_buf(win)
        local bufname=vim.api.nvim_buf_get_name(buf)
        padding=math.max(padding,#vim.fn.fnamemodify(bufname,':t'))
    end
    for _,tabid in ipairs(vim.api.nvim_list_tabpages()) do
        local win=vim.api.nvim_tabpage_get_win(tabid)
        local buf=vim.api.nvim_win_get_buf(win)
        local tabnr=vim.api.nvim_tabpage_get_number(tabid)
        local bufname=vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf),':t')
        local str=('%s %s%s'):format(bufname,(' '):rep(padding-#bufname),tabnr)
        if #str>maxwidth then maxwidth=#str end
        vim.api.nvim_buf_set_lines(M.buf,tabnr-1,tabnr,false,{str})
        if tabnr==vim.fn.tabpagenr() then
            vim.api.nvim_buf_set_extmark(M.buf,M.ns,tabnr-1,0,{
                hl_group='ErrorMsg',
                end_col=#str,
            })
        end
    end
    local old_win=M.win
    M.win=vim.api.nvim_open_win(M.buf,false,{
        relative='editor',
        width=maxwidth,
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
end
local timeout
function M.setup()
    M.buf=vim.api.nvim_create_buf(false,true)
    local last_tab=vim.fn.tabpagenr()
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
                M.show()
            else
                refresh()
            end
        end)
    end)
end
function M.show()
    M.opened=true
    refresh()
    if timeout then timeout:close() timeout=nil end
    timeout=vim.defer_fn(function ()
        timeout=nil
        M.opened=false
        refresh()
    end,1000)
end
return M
