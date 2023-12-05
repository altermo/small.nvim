---a looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong line
local M={
    ns=vim.api.nvim_create_namespace'small_zenall',
    buffers={},
}
function M.redraw(buf)
    local zen='   '
    vim.api.nvim_buf_clear_namespace(buf,M.ns,0,-1)
    local win=vim.fn.win_findbuf(buf)[1]
    vim.wo[win].statuscolumn=zen
    local view=vim.fn.winsaveview()
    local width=vim.api.nvim_win_get_width(win)
    for row=0,vim.api.nvim_buf_line_count(buf) do
        pcall(vim.api.nvim_buf_set_extmark,buf,M.ns,row,width+view.leftcol-#zen*2,{
            virt_text_pos='inline',
            virt_text={{zen}},
        })
    end
end
function M.run(buf)
    buf=vim.fn.bufnr(buf)
    local win=vim.fn.win_findbuf(buf)[1]
    vim.wo[win].showbreak=''
    vim.wo[win].wrap=false
    vim.wo[win].cursorline=false
    vim.wo[win].signcolumn='no'
    local function redraw() M.redraw(buf) end
    vim.api.nvim_create_autocmd({
        'CursorMoved',
        'CursorMovedI',
        'TextChanged',
        'TextChangedI',
        'TextChangedP',
        'WinResized',
        'WinNew',
        'WinLeave',
    },{
            buffer=buf,
            callback=redraw
        })
    M.redraw(buf)
end
if vim.dev then
    M.run(0)
end
return M
