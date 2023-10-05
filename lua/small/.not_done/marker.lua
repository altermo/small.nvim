local M={}
function M.mark_file(mark)
    vim.fn.setpos("'"..mark,vim.fn.getpos('.'))
end
function M.del_mark(mark)
end
function M.select_between_marks()
    local mark2file
    local select=getmarks()
    for k,v in ipairs(select) do
        if mark2file[v]~=nil then
            select[k]={v,mark2file[v]}
        end
    end
    vim.ui.select(select)
end
return M
