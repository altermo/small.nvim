local M={}
function M.toggle()
    vim.cmd.Lexplore{range={20}}
end
function M.setup()
    vim.g.netrw_keepdir=0
    vim.g.netrw_banner=0
    vim.g.netrw_liststyle=3
end
return M
