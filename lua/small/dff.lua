local modelib=require'small.lib.mode'

---@alias small.dff.stat
---|'back'
---|'esc'
---|'done'

---@class small.dff.search_obj
---@field slist string[]
---@field _slist_draw string[]
---@field premark string[]?
---@field range_start number
---@field range_end number
---@field col number
---@field conf small.dff.base_config
---@field altchar string|'error'
---@field history {k:string,rs:number,re:number,col:number}[]
---@field stat 'back'|'done'?

---@class small.dff.base_config
---@field ending string
---@field display 'list'|'block'
---@field skip_one boolean
local default_conf={ending='\n',display='block',skip_one=true}

---@class small.dff.config
---@field ending string?
---@field display 'list'|'block'?
---@field skip_one boolean?

---@param list string[]
---@return nil
local function make_it_slist(list)
    table.sort(list)
    vim.fn.uniq(list)
end

---@param obj small.dff.search_obj
---@return boolean
local function all_same(obj)
    if #obj.slist==0 then return false end
    local char=obj.slist[obj.range_start]:sub(obj.col,obj.col)
    for i=obj.range_start,obj.range_end do
        if obj.slist[i]:sub(obj.col,obj.col)~=char then return false end
    end
    return true
end

---@param obj small.dff.search_obj
local function inc_while_all_same(obj)
    while all_same(obj) do
        obj.col=obj.col+1
    end
end

---@param obj small.dff.search_obj
---@param data small.mode.on_redraw_param
local function draw(obj,data)
    if #obj.slist==0 then
        return {'\x1b[95m NO ITEMS \x1b[m'}
    end
    if obj.conf.display=='list' then
        local lines={}
        for i=obj.range_start,obj.range_end do
            local text=obj._slist_draw[i]
            local pretext=text:sub(1,obj.col)
            local char=text:sub(obj.col+1,obj.col+1)
            local postext=text:sub(obj.col+2)
            if #text==obj.col then char='^M' end
            table.insert(lines,('\x1b[90m%s\x1b[95m%s\x1b[m%s'):format(pretext,char,postext))

            if (i-obj.range_start+3)>data.height then break end
        end
        local search=vim.fn.join(vim.tbl_map(function (o) return o.k end,obj.history),'')
        table.insert(lines,1,':'..search)
        return lines
    end
    assert(obj.conf.display=='block')
    local blocks={{}}
    local total_width=0
    local max_len=0
    local offset=obj.range_start
    for i=obj.range_start,obj.range_end do
        local text=obj._slist_draw[i]
        local pretext=text:sub(1,obj.col)
        local char=text:sub(obj.col+1,obj.col+1)
        local postext=text:sub(obj.col+2)
        local len=#pretext+#char+#postext
        if len>max_len then max_len=len end
        if #text==obj.col then char='^M' end
        table.insert(blocks[#blocks],('\x1b[90m%s\x1b[95m%s\x1b[m%s'):format(pretext,char,postext))
        -- table.insert(blocks[#blocks],('%s%s%s'):format(pretext,char,postext))
        if (i-offset+3)>data.height then
            blocks[#blocks].width=max_len+1
            total_width=total_width+max_len+2
            max_len=0
            offset=i+1
            table.insert(blocks,{})
            if total_width>data.width then break end
        end
    end
    blocks[#blocks].width=max_len+1
    local lines={}
    for i=1,data.height-1 do
        local line={}
        for _,block in ipairs(blocks) do
            if block[i] then
                -- table.insert(line,block[i]..(' '):rep(block.width-(#block[i])))
                table.insert(line,block[i]..(' '):rep(block.width-(#block[i]-#('\x1b[90m\x1b[95m\x1b[m'))))
            end
        end
        table.insert(lines,table.concat(line,' '))
    end
    local search=vim.fn.join(vim.tbl_map(function (o) return o.k end,obj.history),'')
    table.insert(lines,1,':'..search)
    return lines
end

---@param obj small.dff.search_obj
---@return boolean?
local function back(obj)
    local o=table.remove(obj.history)
    if not o then return true end
    obj.range_start=o.rs
    obj.range_end=o.re
    obj.col=o.col
end

---@param obj small.dff.search_obj
---@param key string
---@return number?,number?
local function get_first_and_last(obj,key)
    local i=obj.range_start
    while i<=obj.range_end and obj.slist[i]:sub(obj.col,obj.col)~=key do i=i+1 end
    if i>obj.range_end then return end
    local first=i
    while obj.range_end>=i+1 and obj.slist[i+1]:sub(obj.col,obj.col)==key do i=i+1 end
    return first,i
end

---@param obj small.dff.search_obj
---@param key string
---@return string?
local function send_key(obj,key)
    table.insert(obj.history,{k=key,rs=obj.range_start,re=obj.range_end,col=obj.col})
    if key==obj.conf.ending then
        for i=obj.range_start,obj.range_end do
            if #obj.slist[i]==obj.col-1 then
                return obj.slist[i]
            end
        end
        table.remove(obj.history)
    else
        if key==obj.altchar then
            key=obj.conf.ending
        end
        local first,last=get_first_and_last(obj,key)
        if (not first) or (not last) then table.remove(obj.history) return end
        if first==last then return obj.slist[first] end
        obj.col=obj.col+1
        obj.range_start=first
        obj.range_end=last
        inc_while_all_same(obj)
    end
end

---@param create_obj small.dff.search_obj|(fun(stat:small.dff.stat|'first'):small.dff.search_obj)
---@param callback fun(stat:small.dff.stat,msg:string):any
---@param handle fun(string?):any
local function start_search(create_obj,callback,handle)
    local call=type(create_obj)=='function'

    local obj=create_obj('first')

    local stat
    stat=obj.stat or 'done'

    while #obj.slist==1 and obj.conf.skip_one do
        local ret=callback(stat,obj.slist[1])
        if (not call) or ret then return handle(ret) end
        obj=create_obj(stat)
    end
    inc_while_all_same(obj)

    local function handle_(ret)
        handle(ret)
        return true
    end

    modelib.open(function (data)
        local key=data.data
        if key then
            key=({['\r']='\n',['\n']='\r'})[key] or key
            if key==modelib.escape then
                stat='esc'
                local ret=callback(stat,'')
                return handle_(ret)
            elseif key==modelib.backspace then
                if back(obj) then
                    stat='back'
                    local ret=callback(stat,'')
                    if (not call) or ret then return handle_(ret) end
                    obj=create_obj(stat)
                else
                    return draw(obj,data)
                end
            else
                local r=send_key(obj,key)
                if r then
                    stat='done'
                    local ret=callback(stat,r)
                    if (not call) or ret then return handle_(ret) end
                    obj=create_obj(stat)
                else
                    return draw(obj,data)
                end
            end
            assert(call)

            while #obj.slist==1 and obj.conf.skip_one do
                local ret=callback(stat,obj.slist[1])
                if (not call) or ret then return handle_(ret) end
                obj=create_obj(stat)
            end
            inc_while_all_same(obj)
        end
        return draw(obj,data)
    end,'dff-file-explorer-'..vim.fn.rand(),true)
end

---@class small.dff.search_obj_conf
---@field slist string[]
---@field altchar string
---@field premark string[]?
---@field conf small.dff.base_config

---@param o small.dff.search_obj_conf
---@return small.dff.search_obj
local function make_obj(o)
    local slist_draw={}
    for k,v in ipairs(o.slist) do
        if o.altchar=='error' then
            assert(not v:find(o.conf.ending,1,true))
        else
            assert(not v:find(o.altchar,1,true))
            v=v:gsub(vim.pesc(o.conf.ending),vim.pesc(o.altchar))
        end
        if o.premark then
            v=assert(o.premark[k])..v
        end
        table.insert(slist_draw,v)
    end
    ---@type small.dff.search_obj
    return {
        _slist_draw=slist_draw,
        history={},
        slist=o.slist,
        altchar=o.altchar,
        premark=o.premark,
        range_start=1,
        range_end=#o.slist,
        col=1,
        conf=o.conf,
    }
end

local M={conf=default_conf}

---@param path string?
---@param conf_ small.dff.config?
function M.file_expl(path,conf_)
    local conf=conf_ and vim.tbl_deep_extend('force',default_conf,conf_) or default_conf
    path=vim.fs.normalize(vim.fn.fnamemodify(path or '.',':p'))
    start_search(function ()
        local files=vim.fn.readdir(path)
        make_it_slist(files)
        local mark=vim.tbl_map(function (i)
            return vim.fn.isdirectory(vim.fs.joinpath(path,i))==1 and '/' or ' '
        end,files)
        return make_obj{
            slist=files,
            altchar='/',
            premark=mark,
            conf=conf,
        }
    end,function (stat,msg)
        if stat=='back' then
            if path=='/' and conf.skip_one then
                return path
            end
            path=vim.fs.dirname(path)
            return
        elseif stat=='esc' then
            return path
        elseif stat=='done' then
            path=vim.fs.joinpath(path,msg)
            if vim.fn.isdirectory(path)==0 then return path end
            return
        end
    end,function (ret)
        if path then vim.cmd.edit(ret) end
    end)
end

return M
