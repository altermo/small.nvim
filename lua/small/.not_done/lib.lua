local M={}
---@param s string
---@param i number
---@param j number
---@return string
function M.utf8_sub(s,i,j)
    local pos=vim.str_utf_pos(s) --[[@as number[]]
    j=j or -1
    if i<0 then i=#pos+i+1 end
    if j<0 then j=#pos+j+1 end
    local start=pos[i]
    local end_=pos[j]
    return s:sub(start,end_+vim.str_utf_end(s,end_))
end
M.utf8_len=vim.api.nvim_strwidth
---@return string?
function M.pos_tree_lang()
    local stat,parser=pcall(vim.treesitter.get_parser,0)
    if not stat then return end
    local curpos=vim.api.nvim_win_get_cursor(0)
    local row,col=curpos[1]-1,curpos[2]
    local lang=parser:language_for_range({row,col,row,col})
    return lang:lang()
end
---@param self LanguageTree
---@param range Range4
---@return LanguageTree[]
function M.languages_for_range(self,range,_s)
    _s=_s or {}
    table.insert(_s,1,self)
    for _, child in pairs(self:children()) do
        if child:contains(range) then
            return M.languages_for_range(child,range,_s)
        end
    end
    return _s
end
---@param range Range4
---@param nodetype string
---@return boolean
function M.in_node_type(range,nodetype,opts)
    opts=opts or {}
    local parser=vim.treesitter.get_parser(opts.bufnr,opts.lang)
    for _,lang_tree in ipairs(M.languages_for_range(parser,range)) do
        local node=lang_tree:named_node_for_range(range)
        while node do
            if node:type()==nodetype then return true end
            node=node:parent()
        end
    end
    return false
end
---@param nodetype string
---@param range Range4|nil
---@return boolean
function M.in_node_type2(nodetype,range,opts)
    if not range then
        local pos = vim.api.nvim_win_get_cursor(0)
        range={pos[1]-1,pos[2],pos[1]-1,pos[2]+(vim.api.nvim_get_mode()=='i' and 0 or 1)}
    end
    opts=opts or {}
    local parser=vim.treesitter.get_parser(opts.bufnr,opts.lang)
    local query=vim.treesitter.query.parse(opts.lang or vim.bo[opts.bufnr or 0].filetype,('(%s) @cap'):format(nodetype))
    local _range=require'vim.treesitter._range'
    for _,lang_tree in ipairs(M.languages_for_range(parser,range)) do
        local tree=lang_tree:tree_for_range(range)
        if tree then
            for _,node in query:iter_captures(tree:root(),opts.bufnr,0,-1) do
                if _range.contains({node:range()},range) then return true end
            end
        end
    end
    return false
end
--TODO: make somehow use of vim.ui.input
---@param timeout? number
---@param update? fun(inp:string)
---@return string
function M.timeout_input(timeout,update)
    timeout=timeout or 500
    local ret=''
    local function print_prompt(text)
        vim.api.nvim_echo({},false,{})
        vim.cmd('redraw')
        vim.api.nvim_echo({{'>','Question'},{text}},false,{})
    end
    print_prompt(ret)
    local key=vim.fn.getcharstr()
    while true do
        if key=='\r' then break
        elseif key=='\x80kb' then ret=ret:sub(1,-2)
        else ret=ret..key end
        print_prompt(ret)
        if update then update(ret) end
        local _,status=vim.wait(timeout,function ()
            ---@diagnostic disable-next-line: redundant-parameter
            key=vim.fn.getcharstr(0)
            return key~=''
        end)
        if status==-1 then break end
    end
    return ret
end
---@param preset string
---@param on_confirm fun(inp:string?)
---@param opt table
function M.preset_input(preset,on_confirm,opt)
    opt=vim.tbl_extend('force',{
        completion=nil,
        prompt='>',
        prehl='Comment',
    },opt)
    vim.api.nvim_echo({{opt.prompt,'Normal'},{preset,opt.prehl}},false,{})
    local char=vim.fn.getcharstr()
    if char=='\27' then
        on_confirm(nil) return
    elseif char=='\r' then
        on_confirm(preset) return
    end
    vim.ui.input({
        prompt=opt.prompt,
        default=char,
        completion=opt.completion,
    },on_confirm)
end
---@return userdata
M.userdata=function () return newproxy(true) end
---@param source string
---@return any
function M.req(source)
    package.loaded[source]=nil
    return require(source)
end
---@generic T,P
---@param fn fun(...:T,cb:fun(arg:P)):P
---@param ... T
---@return P
function M.psudo_async(fn,...)
    local co=assert(coroutine.running())
    local args={...}
    table.insert(args,function (...) coroutine.resume(co,...) end)
    fn(unpack(args))
    return coroutine.yield(co)
end
return M
