local M={}
function M.setup()
    vim.api.nvim_create_autocmd({'Filetype'},{callback=function (args)
        local buf=args.buf
        vim.api.nvim_buf_call(buf,function()
            vim.fn.termopen({'emacsclient','-c','-a','emacs','-nw','--',args.file},{on_exit=function()
                pcall(vim.cmd.bdelete,{buf,bang=true})
            end})
            vim.api.nvim_buf_set_name(buf,args.file)
        end)
        if buf==vim.api.nvim_get_current_buf() then vim.cmd.startinsert() end
    end,pattern='org',group=vim.api.nvim_create_augroup('small_emacs_org',{})})
end
if vim.dev then
    M.setup()
end
return M
