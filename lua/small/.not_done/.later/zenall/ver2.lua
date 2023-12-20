local M={
    ns=vim.api.nvim_create_namespace'small_zenall',
    buffers={},
}
function M.redraw(buf)
    vim.api.nvim_buf_clear_namespace(buf,M.ns,0,-1)
    local win=vim.fn.win_findbuf(buf)[1]
    vim.wo[win].showbreak=''
    vim.wo[win].wrap=false
    vim.wo[win].cursorline=false
    vim.wo[win].signcolumn='no'
    local view=vim.fn.winsaveview()
    local width=vim.api.nvim_win_get_width(win)
    local zen=(' '):rep(vim.fn.floor(width/8))
    vim.wo[win].statuscolumn=''
    for row=0,vim.api.nvim_buf_line_count(buf) do
        pcall(vim.api.nvim_buf_set_extmark,buf,M.ns,row,view.leftcol,{
            virt_text_pos='inline',
            virt_text={{zen}},
        })
        pcall(vim.api.nvim_buf_set_extmark,buf,M.ns,row,width+view.leftcol-#zen-#zen,{
            virt_text_pos='inline',
            virt_text={{zen}},
        })
    end
end
function M.run(buf)
    buf=buf==0 and vim.api.nvim_get_current_buf() or buf
    local function redraw()
        M.redraw(buf)
        vim.schedule_wrap(M.redraw)(buf)
    end
    vim.api.nvim_create_autocmd({
        'CursorMoved',
        'CursorMovedI',
        'TextChanged',
        'TextChangedI',
        'TextChangedP',
        'WinResized',
        'WinNew',
        'WinLeave',
        'BufWinEnter',
    },{
            buffer=buf,
            callback=redraw,
            group=vim.api.nvim_create_augroup('small_zenall',{}),
        })
    M.redraw(buf)
end
if vim.dev then
    M.run(0)
end
return M
