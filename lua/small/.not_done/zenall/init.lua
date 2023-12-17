local M={
    ns=vim.api.nvim_create_namespace'small_zenall',
}
function M.attach(ibuf)
    ibuf=ibuf or 0
    vim.api.nvim_buf_attach(ibuf,false,{on_lines=function (_,buf,_,first,_,last,_)
        vim.schedule(function ()
            first,last=first,last
            vim.api.nvim_buf_clear_namespace(buf,M.ns,first,last+1)
            local win=vim.fn.win_findbuf(buf)[1]
            vim.wo[win].showbreak=''
            vim.wo[win].wrap=false
            vim.wo[win].cursorline=false
            vim.wo[win].signcolumn='no'
            vim.wo[win].statuscolumn=''
            local view
            vim.api.nvim_win_call(win,function ()
                view=vim.fn.winsaveview()
            end)
            local width=vim.api.nvim_win_get_width(win)
            local zen=(' '):rep(vim.fn.floor(width/8))
            for row=first,last do
                pcall(vim.api.nvim_buf_set_extmark,buf,M.ns,row,view.leftcol,{
                    virt_text_pos='inline',
                    virt_text={{zen}},
                    undo_restore=false,
                    invalidate=true,
                })
            end
        end)
    end,preview=true})
end
if vim.dev then
    M.attach()
end
return M
