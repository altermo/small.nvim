local M={ns=vim.api.nvim_create_namespace'small_zenall'}
function M.run()
    vim.api.nvim_set_decoration_provider(M.ns,{
        on_win=function (_,_)
            return true
        end,
        on_line=function (_,_,bufnr,row)
            vim.api.nvim_buf_set_extmark(bufnr,M.ns,row,0,{
                ephemeral=true,
                virt_text_pos='inline',
                virt_text={{'  '}},
            })
        end
    })
end
if vim.dev then
    M.run()
end
return M
