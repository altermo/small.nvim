local M={}
--TODO: continue
function M.setup()
    vim.api.nvim_create_autocmd({'Filetype'},{callback=function (args)
        vim.api.nvim_win_set_buf(0,vim.api.nvim_create_buf(true,true))
        vim.api.nvim_buf_delete(args.buf,{})
    vim.fn.termopen('emacs '..args.file)
    end,pattern='org',group=vim.api.nvim_create_augroup('small_emacs_org',{})})

end
if vim.dev then
    M.setup()
end
return M
