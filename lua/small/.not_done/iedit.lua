local M={ns=vim.api.nvim_create_namespace'small_iedit'}
function M.select(pos1,pos2)
    vim.highlight.range(0,M.ns,'Visual',pos1,pos2,{inclusive=true})
end
function M.visual()
    M.select('.','v')
end
if vim.dev then
    vim.api.nvim_buf_clear_namespace(0,M.ns,0,-1)
    vim.keymap.set('x','gi',M.visual)
end
return M
