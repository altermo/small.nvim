---Use multiple neovim instances, with each one having only one cursor, and the relay the cursor (and visual select) information to main neovim instance and show with extmarks
local M={}
M.ns=vim.api.nvim_create_namespace'small.multicursor'
function M.handle()
    vim.api.nvim_feedkeys('q','n',true)
    vim.pprint(vim.fn.getreg('a'))
    M.running=false
end
function M.start()
    vim.on_key(function ()
        if M.running then return end
        M.running=true
        vim.api.nvim_feedkeys('qa','n',true)
        vim.defer_fn(M.handle,10)
    end,M.ns)
end
return M
