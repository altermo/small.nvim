local modelib=require'small.lib.mode'

---@alias small.dff.stat
---|'back'
---|'esc'
---|'done'

---@class small.dff.search_obj
---@field slist string[]
---@field _slist_draw string[]
---@field draw fun(pre:string,char:string,post:string,idx:number):string,string,string
---@field range_start number
---@field range_end number
---@field col number
---@field conf small.dff.base_config
---@field altchar string
---@field history {k:string,rs:number,re:number,col:number}[]
---@field ignore_back boolean?

---@class small.dff.base_config
---@field ending string
---@field display 'list'|'block'
---@field skip_one boolean
---@field dir_shash false|'before'|'after'|'included'
local default_conf={ending='\r',display='block',skip_one=true,dir_shash='before'}

---@class small.dff.config
---@field ending string?
---@field display 'list'|'block'?
---@field skip_one boolean?
---@field dir_shash false|'before'|'after'|'included'?

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
        local pretext=text:sub(1,obj.col-1)
        local char=text:sub(obj.col,obj.col)
        local postext=text:sub(obj.col+1)
        if obj.draw then
            pretext,char,postext=obj.draw(pretext,char,postext,i)
        end
        if #text>max_len then max_len=#text end
        if #text==obj.col-1 then char='^M' end
        table.insert(blocks[#blocks],('\x1b[90m%s\x1b[95m%s\x1b[m%s'):format(pretext,char,postext))
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

    local obj=(not call) and create_obj --[[@as small.dff.search_obj]] or create_obj('first')

    local stat='done'

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
            if key==modelib.escape then
                stat='esc'
                local ret=callback(stat,'')
                return handle_(ret)
            elseif key==modelib.backspace then
                if back(obj) and (not obj.ignore_back) then
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
---@field draw (fun(pre:string,char:string,post:string,idx:number):string,string,string)?
---@field conf small.dff.base_config
---@field ignore_back boolean?

---@param o small.dff.search_obj_conf
---@return small.dff.search_obj
local function make_obj(o)
    local slist_draw={}
    for _,v in ipairs(o.slist) do
        if o.altchar==nil then
            assert(not v:find(o.conf.ending,1,true))
        else
            assert(not v:find(o.altchar,1,true))
            v=v:gsub(vim.pesc(o.conf.ending),vim.pesc(o.altchar))
        end
        table.insert(slist_draw,v)
    end
    ---@type small.dff.search_obj
    return {
        _slist_draw=slist_draw,
        history={},
        slist=o.slist,
        altchar=o.altchar,
        draw=o.draw,
        range_start=1,
        range_end=#o.slist,
        col=1,
        conf=o.conf,
        ignore_back=o.ignore_back,
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
        local mark
        if conf.dir_shash then
            mark=vim.tbl_map(function (i)
                return vim.fn.isdirectory(vim.fs.joinpath(path,i))==1 and '/' or ' '
            end,files)
        end
        if conf.dir_shash=='included' then
            for k,v in ipairs(files) do
                files[k]=v..(mark[k]=='/' and '/' or '')
            end
        end
        return make_obj{
            slist=files,
            altchar=conf.dir_shash~='included' and '/' or '\0',
            draw=conf.dir_shash=='before' and function (pre,char,post,idx)
                return mark[idx]..pre,char,post
            end or conf.dir_shash=='after' and function (pre,char,post,idx)
                    return pre,char,post..mark[idx]
                end or nil,
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
            if ret then vim.cmd.edit(vim.uv.fs_realpath(ret) or ret) end
        end)
end

---@param path string?
---@param conf_ small.dff.config?
function M.markdown_headings(path,conf_)
    local conf=conf_ and vim.tbl_deep_extend('force',default_conf,conf_) or default_conf
    path=path or vim.api.nvim_buf_get_name(0)
    assert(vim.fn.filereadable(path)==1)
    local source=vim.fn.readblob(path)
    local parser=vim.treesitter.get_string_parser(source,'markdown')
    local root=parser:parse(true)[1]:root()
    local query=vim.treesitter.query.parse('markdown',[[
    (setext_heading
        heading_content: (_) @h
        (setext_h1_underline))
    (setext_heading
        heading_content: (_) @h
        (setext_h2_underline))
    (atx_heading
        (atx_h1_marker)
        heading_content: (_) @h)
    (atx_heading
        (atx_h2_marker)
        heading_content: (_) @h)
    (atx_heading
        (atx_h3_marker)
        heading_content: (_) @h)
    (atx_heading
        (atx_h4_marker)
        heading_content: (_) @h)
    (atx_heading
        (atx_h5_marker)
        heading_content: (_) @h)
    (atx_heading
        (atx_h6_marker)
        heading_content: (_) @h)
    ]])
    local positions={}
    local names={}
    for _,node in query:iter_captures(root,source,0,-1) do
        local heading=vim.treesitter.get_node_text(node,source)
        local name=heading:match('<!%-%-%s*(%w+)%s*-->')
        if name then
            if positions[name] then
                error('Duplicate heading: '..name)
            end
            positions[name]=(node:range())+1
            table.insert(names,name)
        end
    end
    make_it_slist(names)
    start_search(make_obj{
        slist=names,
        conf=conf,
        altchar='\n',
        ignore_back=true,
    },function (stat,msg)
            if stat=='done' then
                return positions[msg]
            end
        end,function (ret)
            vim.cmd.edit(path)
            if ret then
                vim.fn.setcursorcharpos(ret,0)
                vim.cmd.normal{'zt',bang=true}
            end
        end)
end

---@param path string?
---@param conf_ small.dff.config?
function M.lua_tags(path,conf_)
    local conf=conf_ and vim.tbl_deep_extend('force',default_conf,conf_) or default_conf
    path=path or vim.api.nvim_buf_get_name(0)
    assert(vim.fn.filereadable(path)==1)
    local positions={}
    local names={}
    local row=0
    for line in io.lines(path) do
        row=row+1
        local tag=line:match('%*(%w+)%*')
        if tag then
            if positions[tag] then
                error('Duplicate tag: '..tag)
            end
            positions[tag]=row
            table.insert(names,tag)
        end
    end
    make_it_slist(names)
    start_search(make_obj{
        slist=names,
        conf=conf,
        altchar='\n',
        ignore_back=true,
    },function (stat,msg)
            if stat=='done' then
                return positions[msg]
            end
        end,function (ret)
            vim.cmd.edit(path)
            if ret then
                vim.fn.setcursorcharpos(ret,0)
                vim.cmd.normal{'zt',bang=true}
            end
        end)
end

---@param path string
---@param conf_ small.dff.config?
function M.auto_open(path,conf_)
    if vim.fn.isdirectory(path)==1 then
        M.file_expl(path,conf_)
    elseif vim.fn.fnamemodify(path,':e')=='md' then
        M.markdown_headings(path,conf_)
    elseif vim.fn.fnamemodify(path,':e')=='lua' then
        M.lua_tags(path,conf_)
    else
        if vim.api.nvim_buf_get_name(0)==vim.fn.resolve(path) then
        else
            vim.cmd.edit(path)
        end
    end
end

return M
