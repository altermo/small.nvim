local M={ns=vim.api.nvim_create_namespace'small_zenall'}
M.nss={}
function M.get_ns(win)
    local buf=vim.api.nvim_win_get_buf(win)
    local count=(vim.b[buf].small_zenall_win_ns or 0)+1
    vim.b[buf].small_zenall_win_ns=count
    if not M.nss[count] then
        M.nss[count]=vim.api.nvim_create_namespace''
    end
    return M.nss[count]
end
function M.redraw(win,topline,botline)
    local ns=M.get_ns(win)
    local view=vim.w[win].small_zenall_view
    local width=vim.api.nvim_win_get_width(win)
    local zen=(' '):rep(vim.fn.floor(width/8))
    vim.wo[win].showbreak=zen..vim.opt_global.showbreak:get()
    vim.wo[win].wrap=true
    local buf=vim.api.nvim_win_get_buf(win)
    if vim.w[win].small_zenall_prev_ns then
        vim.api.nvim__win_del_ns(win,vim.w[win].small_zenall_prev_ns)
    end
    vim.api.nvim__win_add_ns(win,ns)
    vim.w[win].small_zenall_prev_ns=ns
    for row=topline,botline do
        vim.api.nvim_buf_set_extmark(buf,ns,row,view.leftcol,{
            virt_text={{zen}},
            virt_text_pos='inline',
            scoped=true,
            right_gravity=false,
        })
        local line_len=#vim.fn.getline(row+1)
        local vwidth=width-#zen-#zen
        local ovwidth=vwidth
        if vim.wo[win].breakindent then
            vwidth=vwidth-(vim.fn.getline(row+1):find('[^%s]') or -1)+1
        end
        if vim.opt_global.showbreak:get()~='' then
            vwidth=vwidth-vim.api.nvim_strwidth(vim.opt_global.showbreak:get())
        end
        ---TODO: setting 'linebreak' breaks things
        for vcol=ovwidth,line_len, vwidth do
            vim.api.nvim_buf_set_extmark(buf,ns,row,vcol,{
                virt_text_pos='inline',
                virt_text={{zen}},
                scoped=true,
            })
        end
    end
end
function M.setup()
    local done={}
    vim.api.nvim_set_decoration_provider(M.ns,{
        on_start=function ()
            done={}
        end,
        on_win=function (_,winid,bufnr,topline,botline)
            if not done[bufnr] then
                done[bufnr]=true
                for _,win in ipairs(vim.fn.win_findbuf(bufnr)) do
                    vim.api.nvim_win_call(win,function ()
                        --IMPORTANT: have this before nvim_buf_clear_namespace
                        vim.w[win].small_zenall_view=vim.fn.winsaveview()
                    end)
                end
                for i=1,(vim.b[bufnr].small_zenall_win_ns or 0) do
                    vim.api.nvim_buf_clear_namespace(bufnr,M.nss[i],0,-1)
                end
                vim.b[bufnr].small_zenall_win_ns=0
            end
            if vim.bo[bufnr].buftype~='' then return end
            M.redraw(winid,topline,botline)
        end})
end
if vim.dev then
    M.setup()
end
return M
