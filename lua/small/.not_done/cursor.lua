local M={conf={ns=nil}}
function M.get_ns()
    return M.conf.ns or vim.api.nvim_create_namespace('small_cursor')
end
---@param buf? number
---@return number[][]
function M.get_cursors_ext(buf)
    local ns=M.get_ns()
    return vim.api.nvim_buf_get_extmarks(buf or 0,ns,0,-1,{details=true})
end
---@param pos? string|number[]
---@param buf? number
---@return number?
---@return number?
function M.create_cursor(pos,buf)
    local ns=M.get_ns()
    if type(pos)~='table' then
        local gpos=vim.fn.getpos(pos or '.')
        pos={gpos[2]-1,gpos[3]-1+gpos[4]}
    end
    for _,v in ipairs(M.get_cursors_ext(buf)) do
        if v[2]==pos[1] and v[3]==pos[2] then
            return nil,v[1]
        end
    end
    return vim.api.nvim_buf_set_extmark(buf or 0,ns,pos[1],pos[2],{
        hl_group='Cursor',end_col=pos[2]+1,
    })
end
if vim.dev then
    M.create_cursor()
    vim.pprint(M.get_cursors_ext(0))
end
return M
