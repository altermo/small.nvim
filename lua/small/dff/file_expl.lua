--TODO:
--dff as file manager
--have the ability to see a file with another name
---EXAMPLE:
---main_c.lua > c.lua
---main_foo_b.lua > b.lua
--or fast key (maybe autogenerate)
---EXAMPLE:
---main_c.lua > C
---main_foo_b.lua > F
local dff=require'small.dff.dff'
local mode=require'small.lib.mode'
local M={}
---@param path string?
---@param conf small.dff.config?
function M.open(path,conf)
    conf=conf or require'small.dff.init'.conf
    path=vim.fs.normalize(vim.fn.fnamemodify(path or '.',':p'))
    local search=dff.create_search(vim.fn.readdir(path),conf)
    local function fn(key)
        if #search.list==1 then
            path=vim.fs.joinpath(path,search.list[1])
            if vim.fn.isdirectory(path)==0 then vim.cmd.edit(path) return true
            else
                search=dff.create_search(vim.fn.readdir(path),conf)
                return
            end
        end
        if key==mode.enter then key='\n' end
        if key==mode.escape then vim.cmd.edit(path) return true end
        if key==mode.backspace then
            if dff.back(search) then
                repeat path=vim.fs.dirname(path) --[[@as string]] until path=='/' or #vim.fn.readdir(path)~=1
                search=dff.create_search(vim.fn.readdir(path),conf)
            end
            return
        end
        local ret=dff.send_key(search,key)
        if ret then
            path=vim.fs.joinpath(path,ret)
            if vim.fn.isdirectory(path)==0 then vim.cmd.edit(path) return true end
            search=dff.create_search(vim.fn.readdir(path),conf)
            while #search.list==1 do
                path=vim.fs.joinpath(path,search.list[1])
                if vim.fn.isdirectory(path)==0 then vim.cmd.edit(path) return true
                else
                    search=dff.create_search(vim.fn.readdir(path),conf)
                    return
                end
            end
        end
    end
    mode.open(function (k)
        local key=k.data
        if key then if fn(key) then return true end end
        return M.draw(search,path)
    end,'dff-file-explorer-'..vim.fn.rand(),true)
end
---@param obj smakk.dff.search_obj
---@param rpath string
function M.draw(obj,rpath)
    local lines={}
    for i=obj.range[1],obj.range[2] do
        local path=obj.list[i]
        local text=(vim.fn.isdirectory(vim.fs.joinpath(rpath,path))==1 and '/' or ' ')..path
        local pretext=text:sub(1,obj.col)
        local char=text:sub(obj.col+1,obj.col+1)
        local postext=text:sub(obj.col+2)
        if #text==obj.col then char='^M' end
        table.insert(lines,('\x1b[90m%s\x1b[95m%s\x1b[m%s'):format(pretext,char,postext))
        if i-obj.range[1]>vim.o.lines then break end
    end
    local search=vim.fn.join(vim.tbl_map(function (o) return o.k end,obj.history),'')
    table.insert(lines,1,':'..search)
    return lines
end
return M
