local M={}
function M.add_note()
    vim.ui.input({},function (content)
        if not content then return end
        vim.ui.input({},function (name)
            if not name then return end
            M.add_note_file(name,content)
        end
        )
    end)
end
function M.search()
end
function M.get_note()
end
function M.detete_note()
end
return M
