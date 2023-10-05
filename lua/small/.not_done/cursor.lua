---@class small.cursor.Cursor
---@field extmark number
---@field hidden boolean
---@field original_pos number[]
---@field ns number

local M={conf={ns=nil}}
function M.get_ns()
    return M.conf.ns or vim.api.nvim_create_namespace('small_cursor')
end
---@param pos? string|number[]
---@param buf? number
---@return small.cursor.Cursor
function M.create_cursor(pos,buf)
    if type(pos)~='table' then
        local gpos=vim.fn.getpos(pos or '.')
        pos={gpos[2]-1,gpos[3]-1+gpos[4]}
    end
    local ns=M.get_ns()
    return {
        hidden=false,
        extmark=vim.api.nvim_buf_set_extmark(buf or 0,ns,pos[1],pos[2],{
            hl_group='Cursor',end_col=pos[2]+1
        }),
        original_pos=pos,
        ns=ns,
    }
end
if vim.dev then
    vim.pprint(M.create_cursor())
end
return M
