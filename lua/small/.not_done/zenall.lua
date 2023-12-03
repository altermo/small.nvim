local M={ns=vim.api.nvim_create_namespace'small_zenall'}
function M.run()
    M.zen_windows={}
    vim.api.nvim_set_decoration_provider(M.ns,{
        on_win=function (_,winid)
            return M.zen_windows[winid]
        end,
        on_line=function (_,winid,bufnr,row)
            vim.lg(winid,bufnr,row)
        end
    })
end
if vim.dev then
    M.run()
end
return M
