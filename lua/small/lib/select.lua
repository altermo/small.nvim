local M={}
function M.fn(...)
    vim.ui.select(...)
end
return M.fn,M
