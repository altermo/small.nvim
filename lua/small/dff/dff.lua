--[[ TODO:
main.h
main.c
lib/
>> c >>
main.c
--]]
---@class dff.search_obj
---@field list string[] sorted
---@field range table<number,number>
---@field history table<{k:string,range:table<number,number>,col:number}>
---@field col number
---@field opt dff.config

local M={}
---@param list string[]
---@param opt dff.config
---@return dff.search_obj
function M.create_search(list,opt)
    list=vim.fn.copy(list)
    vim.fn.sort(list)
    vim.fn.uniq(list)
    list=vim.tbl_map(function (value) return value:gsub(opt.ending,'/') end,list)
    local obj={
        list=list,
        range={1,#list},
        history={},
        opt=opt,
        col=1,
    }
    if #list~=1 then M.inc_while_all_same(obj) end
    return obj
end
---@param obj dff.search_obj
function M.inc_while_all_same(obj)
    while M.all_same(obj) do
        obj.col=obj.col+1
    end
end
---@param obj dff.search_obj
---@param key string
function M.send_key(obj,key)
    table.insert(obj.history,{k=key,range=obj.range,col=obj.col})
    if key==obj.opt.ending then
        for i=obj.range[1],obj.range[2] do
            if #obj.list[i]==obj.col-1 then
                return obj.list[i]:gsub('/',obj.opt.ending)
            end
        end
    end
    local first,last=M.get_first_and_last(obj,key)
    if not first then table.remove(obj.history) return end
    if first==last then return obj.list[first]:gsub('/',obj.opt.ending) end
    obj.col=obj.col+1
    obj.range={first,last}
    M.inc_while_all_same(obj)
end
---@param obj dff.search_obj
---@param key string
---@return number?
---@return number?
function M.get_first_and_last(obj,key)
    local i=obj.range[1]
    while i<=obj.range[2] and obj.list[i]:sub(obj.col,obj.col)~=key do i=i+1 end
    if i>obj.range[2] then return end
    local first=i
    while obj.range[2]>=i+1 and obj.list[i+1]:sub(obj.col,obj.col)==key do i=i+1 end
    return first,i
end
---@param obj dff.search_obj
---@return boolean?
function M.all_same(obj)
    local char=obj.list[obj.range[1]]:sub(obj.col,obj.col)
    for i=obj.range[1],obj.range[2] do
        if obj.list[i]:sub(obj.col,obj.col)~=char then return end
    end
    return true
end
---@param obj dff.search_obj
---@return boolean?
function M.back(obj)
    local o=obj.history[#obj.history]
    if not o then return true end
    obj.range=o.range
    obj.col=o.col
    table.remove(obj.history)
end
return M
