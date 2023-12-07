local M={}
--TODO: continue
function M.setup()
    vim.api.nvim_create_autocmd({'Filetype'},{callback=function (args)
        vim.fn.termopen({'emacs','-nw','--',args.file})
        vim.api.nvim_buf_set_name(0,args.file)
    end,pattern='org',group=vim.api.nvim_create_augroup('small_emacs_org',{})})

end
if vim.dev then
    M.setup()
end
return M
