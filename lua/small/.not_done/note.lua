local M={conf={
    path=vim.fs.joinpath(vim.fn.stdpath('data') --[[@as string]],'/small-note.txt')
}}
function M.add_note()
    vim.ui.input({},function (content)
        if not content then return end
        vim.fn.writefile({content},M.conf.path,'a')
    end)
end
function M.search_note()
    vim.ui.select(vim.fn.readfile(M.conf.path),{},function() end)
end
function M.detete_note()
    local notes=vim.fn.readfile(M.conf.path)
    vim.ui.select(notes,{},function(_,idx)
        if not idx then return end
        table.remove(notes,idx)
        vim.fn.writefile(notes,M.conf.path)
    end)
end
return M
