local M={ns=vim.api.nvim_create_namespace('small_yank')}
function M.highlight_any(inclusive,regtype,window)
    regtype=regtype or 'v'
    window=window and vim.api.nvim_get_current_win()
    local buf=vim.api.nvim_get_current_buf()
    if M.timer then
        pcall(vim.fn.matchdelete, M.match,window)
        M.timer:close()
    end
    if window then
        local match_s={}
        for row,cols in pairs(vim.region(buf, "'[", "']", regtype, inclusive)) do
            if cols[2]==-1 or cols[2]>#vim.fn.getline(row+1) then
                cols[2]=#vim.fn.getline(row+1)-1
            end
            table.insert(match_s,('\\%('..
                '\\%'..(row+1)..'l'..
                '\\%'..(cols[1]+1)..'c'..
                '.*'..
                '\\%'..(cols[2]+2)..'c'..
                '\\)'))
        end
        M.match=vim.fn.matchadd('Search',table.concat(match_s,[[\|]]),nil,-1,{window=window})
    else
        vim.highlight.range(buf, M.ns, 'Search', "'[", "']", {
            regtype = regtype,
            inclusive = inclusive,
        })
    end
    M.timer=vim.defer_fn(function ()
        M.timer=nil
        pcall(vim.fn.matchdelete, M.match,window)
        pcall(vim.api.nvim_buf_clear_namespace, buf, M.ns, 0, -1)
    end,500)
end
if vim.dev then
    M.highlight_any(nil,nil,true)
    M.highlight_any(nil,nil,true)
    M.highlight_any(nil,nil,true)
    M.highlight_any(nil,nil,true)
end
return M
