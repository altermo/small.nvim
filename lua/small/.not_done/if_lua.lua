---@class small.if_lua.buffer
---@class small.if_lua.window
---@class small.if_lua.blob
---@class small.if_lua.funcref

local if_lua={}
local M={if_lua=if_lua}
M.funcref_mt={
    __len=function (self)
        return self._name
    end,
    __call=function (self,...)
        return vim.fn[self._name](...)
    end
}
M.buffer_mt={
    __call=function (self)
        vim.api.nvim_set_current_buf(self._buf)
    end,
    __len=function (self)
        return vim.api.nvim_buf_line_count(self._buf)
    end,
    __index=function (self,k)
        if k=='name' then
            return vim.fn.fnamemodify(vim.fn.bufname(self._buf),':t')
        elseif k=='fname' then
            return vim.fn.bufname(self._buf)
        elseif k=='number' then
            return self._buf
        elseif k=='insert' then
            return function(_,newline,pos)
                pos=pos or #self+1
                vim.api.nvim_buf_set_lines(self._buf,pos,pos,false,{newline})
            end
        elseif k=='next' then
            return function(_)
                local list=vim.api.nvim_list_bufs()
                local i=1
                while self._buf~=list[i] do i=i+1 end
                return list[i+1]
            end
        elseif k=='previous' then
            return function(_)
                local list=vim.api.nvim_list_bufs()
                local i=1
                while self._buf~=list[i] do i=i+1 end
                return list[i-1]
            end
        elseif k=='isvalid' then
            return function(_)
                return vim.api.nvim_buf_is_valid(self._buf)
            end
        end
        return vim.api.nvim_buf_get_lines(self._buf,k-1,k,false)[1]
    end,
    __newindex=function (self,k,v)
        vim.api.nvim_buf_set_lines(self._buf,k-1,k,false,{v})
    end
}
M.window_mt={
    __call=function (self)
        vim.api.nvim_set_current_buf(self._win)
    end,
    __index=function(self,k)
        if k=='buffer' then
            return vim.api.nvim_win_get_buf(self._win)
        elseif k=='line' then
            return vim.api.nvim_win_get_position(self._win)[1]
        elseif k=='col' then
            return vim.api.nvim_win_get_position(self._win)[2]
        elseif k=='width' then
            return vim.api.nvim_win_get_width(self._win)
        elseif k=='height' then
            return vim.api.nvim_win_get_height(self._win)
        elseif k=='next' then
            return function(_)
                local list=vim.api.nvim_list_wins()
                local i=1
                while self._buf~=list[i] do i=i+1 end
                return list[i+1]
            end
        elseif k=='previous' then
            return function(_)
                local list=vim.api.nvim_list_wins()
                local i=1
                while self._buf~=list[i] do i=i+1 end
                return list[i-1]
            end
        elseif k=='isvalid' then
            return function(_)
                return vim.api.nvim_win_is_valid(self._buf)
            end
        end
    end
}
M.list_mt={
    __call=function (self)
        local i=0
        return function() i=i+1 return self[i] end
    end,
    __index={
        add=function (self,item)
            table.insert(self,item)
        end,
        insert=function (self,item,pos)
            table.insert(self,pos or 1,item)
        end
    },
}
M.dict_mt={
    __len=function (self)
        return vim.tbl_count(self)
    end,
    __call=function (self)
        return pairs(self)
    end
}
M.blob_mt={
    __len=function (self)
        return #self._content
    end,
    __index=function (self,k)
        if k=='add' then
            return function (_,bytes)
                self._content=self._content..bytes
            end
        elseif type(k)=='string' then
            return rawget(self,k)
        end
        return vim.fn.char2nr(self._content:sub(k-1,k-1))
    end,
    __newindex=function (self,k,v)
        self._content=self._content:sub(1,k-1)..vim.fn.nr2char(v)..self._content:sub(k+1)
    end
}
---@param arg? table
---@return table<number,any>
function if_lua.list(arg)
    return setmetatable({unpack(arg or {})},M.list_mt)
end
---@param arg? table
---@return table
function if_lua.dict(arg)
    local dict=setmetatable({},M.dict_mt)
    for k,v in pairs(arg or {}) do dict[k]=v end
    return dict
end
---@param arg? string
---@return small.if_lua.blob
function if_lua.blob(arg)
    return setmetatable({_content=arg or ''},M.blob_mt)
end
---@param name string
---@return small.if_lua.funcref
function if_lua.funcref(name)
    return setmetatable({_name=name},M.funcref_mt)
end
---@param arg? number|string|boolean
---@return small.if_lua.buffer?
function if_lua.buffer(arg)
    local buf=-1
    if type(arg)=='number' then
        buf=arg
    elseif type(arg)=='string' then
        buf=vim.fn.bufnr('^'..buf..'$')
    elseif arg then
        buf=vim.api.nvim_list_bufs()[1]
    else
        buf=vim.api.nvim_get_current_buf()
    end
    if not vim.api.nvim_buf_is_valid(buf) then return end
    return setmetatable({_buf=buf},M.buffer_mt)
end
---@param arg? number|boolean
---@return small.if_lua.window?
function if_lua.window(arg)
    local win=-1
    if type(arg)=='number' then
        win=arg
    elseif arg then
        win=vim.api.nvim_list_wins()[1]
    else
        win=vim.api.nvim_get_current_win()
    end
    if not vim.api.nvim_win_is_valid(win) then return end
    return setmetatable({_win=win},M.window_mt)
end
---@param arg any
---return 'nil'|'number'|'string'|'boolean'|'table'|'function'|
---'thread'|'userdata'|'list'|'dict'|'funcref'|'buffer'|'window'
function if_lua.type(arg)
    if type(arg)=='table' then
        if getmetatable(arg)==M.list_mt then
            return 'list'
        elseif getmetatable(arg)==M.dict_mt then
            return 'dict'
        elseif getmetatable(arg)==M.funcref_mt then
            return 'funcref'
        elseif getmetatable(arg)==M.buffer_mt then
            return 'buffer'
        elseif getmetatable(arg)==M.window_mt then
            return 'window'
        end
    end
    return type(arg)
end
---@param cmds string
function if_lua.command(cmds)
    vim.api.nvim_exec2(cmds,{})
end
---@param expr string
---@return any
function if_lua.eval(expr)
    return vim.api.nvim_eval(expr)
end
---@return string
function if_lua.line()
    return vim.api.nvim_get_current_line()
end
function if_lua.beep()
    io.write('\a')
end
---@param fname string
---@return small.if_lua.buffer
function if_lua.open(fname)
    return M.buffer(vim.fn.bufadd(fname)) --[[@as small.if_lua.buffer]]
end
if_lua.call=vim.call
if_lua.fn=vim.fn
if_lua.lua_version='5.1.5'
---@return {major:number,minor:number,patch:number}
function if_lua.version()
    local ver=vim.version()
    return {major=ver.major,minor=ver.minor,patch=ver.patch}
end
if_lua.g=vim.g
if_lua.b=vim.b
if_lua.w=vim.w
if_lua.t=vim.t
if_lua.v=vim.v
if vim.dev then
    local V=if_lua
    local b=V.funcref('has')
    vim.pprint(#b)
end
return M
