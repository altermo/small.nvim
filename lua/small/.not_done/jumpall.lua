---Rewrite of https://github.com/mizlan/longbow.nvim
local M={conf={labels='abcdefghijklmnopqrstuvwxyz0123456789'}}
---@param keys string
---@return string
function M.generate_sequence(keys,_n)
    _n=_n or 1
    if _n>#keys then return keys:sub(1,1) end
    local char=keys:sub(_n,_n)
    local ret=char
    for i in keys:sub(_n+1):gmatch'.' do
        ret=ret..char..i
    end
    return ret..M.generate_sequence(keys,_n+1)
end
vim.pprint(M.generate_sequence('abcd'))
return M
