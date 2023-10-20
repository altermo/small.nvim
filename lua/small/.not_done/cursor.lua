--[[TODO
Make each cursor be able to have a mode which they are in
Make it so that you can do an action at each cursor
    also preview action at each cursor
Be able to create groups of cursors (buffer/window/id specific)
    And only show in those buffers/windows/a function returning boolean
A telescope selector for cursor (and groups of cursors)
A cursor spawner: looks like a normal cursor but when you trie to use it, it spawns a cursor
A temp cursor: cursor which is temporary and will be deleted once not focused (can be made permanent)
    spawner + temp : a mark system
Option to hide cursor/ make it look different
    Different colors for different modes
Have a main cursor object (which is auto created?)
--]]
---@class cursor.group
---@field content cursor.cursor[]
---@field namespace number
---@class cursor.cursor
---@field mode 'normal'|'_Error'
---@field buffer number
---@field _extmark number
---@field highlight? cursor.highlight
---@field type 'normal'|'temp'|'spawner'
---@class cursor.highlight
---@field hidden? boolean
---@field mode_hl? table<string,string>
---@field select_hl? string

local M={I={}}
---@param pos? number[]|string
---@return number[]
function M.I.get_pos(pos)
    if type(pos)=='table' then return pos end
    local gpos=vim.fn.getpos(pos or '.')
    return {gpos[2]-1,gpos[3]-1+gpos[4]}
end
---@param g cursor.group
---@param position? string|number[]
---@param buf? number
function M.create_cursor(g,position,buf)
    local pos=M.I.get_pos(position)
    table.insert(g.content,{
        mode='normal',
        buffer=buf or 0,
        _extmark=vim.api.nvim_buf_set_extmark(buf or 0,g.namespace,pos[1],pos[2],{hl_group='Cursor',end_col=pos[2]+1,}),
        type='normal',
    })
end
---@param g cursor.group
---@param cur cursor.cursor
function M.jump_to_cursor(g,cur)
    M.create_cursor(g)
    local ext=vim.api.nvim_buf_get_extmark_by_id(cur.buffer,g.namespace,cur._extmark,{})
    vim.api.nvim_win_set_cursor(0,{ext[1]+1,ext[2]})
    vim.api.nvim_buf_del_extmark(cur.buffer,g.namespace,cur._extmark)
    for k,v in ipairs(g.content) do
        if v==cur then table.remove(g.content,k) break end
    end
end
---@param ns? string
---@return cursor.group
function M.create_cursor_group(ns)
    return {
        namespace=ns or vim.api.nvim_create_namespace(''),
        content={},
    }
end
if vim.dev then
    if _G.Group then vim.api.nvim_buf_clear_namespace(0,_G.Group.namespace,0,-1) end
    local g=M.create_cursor_group()
    M.create_cursor(g)
    vim.keymap.set('n','<F12>',function() M.jump_to_cursor(g,g.content[1]) end)
    _G.Group=g
end
return M
