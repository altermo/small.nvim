local M={}
function M.get_folds()
    local ret={}
    local current_fold=0
    for i=1,vim.api.nvim_buf_line_count(0) do
        local foldlevel=vim.fn.foldlevel(i)
        if foldlevel~=current_fold then
            if foldlevel>current_fold then table.insert(ret,1,('%-3s '):format(i)..vim.fn.getline(i)) end
            current_fold=foldlevel
        end
    end
    return ret
end
function M.goto_select_folds(folds)
    require'small.lib.select'(folds,{},function (i)
        if not i then return end
        vim.cmd(i:match('^[^ ]*'))
    end)
end
function M.run() M.goto_select_folds(M.get_folds()) end
return M
