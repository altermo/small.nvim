local M={}
M.enter='\r'
M.backspace='\127'
M.escape='\x1b'
---@param buf number
---@return number[]
local function buf_get_wins(buf)
    return vim.tbl_filter(function (win) return vim.api.nvim_win_get_buf(win)==buf end,vim.api.nvim_list_wins())
end
---@param buf number
---@param lines? string[]|true
---@param pos? number[]
---@param extra? string
local function draw(buf,lines,pos,extra)
    if lines==true then vim.api.nvim_buf_delete(buf,{force=true}) return end
    if not buf then return end
    local wins=buf_get_wins(buf)
    if #wins==0 then return end
    local height=math.max(unpack(vim.tbl_map(function (win) return vim.api.nvim_win_get_height(win) end,wins)))
    local width=math.max(unpack(vim.tbl_map(function (win) return vim.api.nvim_win_get_width(win) end,wins)))
    local out_lines={}
    for row,line in ipairs(lines or {}) do
        if row>height then break end
        local true_width=#line-#(line:gsub('\x1b%[[^a-zA-Z]*[a-zA-Z]',''))+width
        table.insert(out_lines,line:sub(1,true_width))
    end
    vim.api.nvim_buf_set_lines(buf,0,-1,false,out_lines)
    -- if pos then
    --     vim.api.nvim_chan_send(chan,'\x1b['..pos[1]..';'..pos[2]..'H')
    -- else
    --     vim.api.nvim_chan_send(chan,'\x1b[1;1H')
    --     vim.api.nvim_chan_send(chan,'\x1b[?25l')
    -- end
    -- if extra then vim.api.nvim_chan_send(chan,extra) end
end
---@param buf number
---@param fn fun(in:small.mode.on_redraw_param):string[]|true?,number[]?,string?
---@param data any
---return string[]?|true,number[]?,string?
local function pass_params(buf,fn,data)
    if not buf then return end
    local wins=buf_get_wins(buf)
    local height=math.max(0,unpack(vim.tbl_map(function (win) return vim.api.nvim_win_get_height(win) end,wins)))
    local width=math.max(0,unpack(vim.tbl_map(function (win) return vim.api.nvim_win_get_width(win) end,wins)))
    return fn({height=height,width=width,wins=wins,chan=buf,buf=buf,data=data})
end
---@param key string
---@return string
local function key_get_first(key)
    if key:sub(1,1)~='<' then
        return key:sub(1,vim.str_utf_end(key,1)+1)
    end
    return assert(key:sub(assert(vim.regex([[^<\(.-\)*.[^>]*>]]):match_str(key))))
end
---@param on_input fun(in:small.mode.on_redraw_param):string[]|true?,number[]?,string?
---@param startinsert? boolean
---@param bufname? string
---@return fun(lines?:string[]|true,pos?:number[],extra?:string)
function M.open(on_input,bufname,startinsert)
    local buf=vim.api.nvim_create_buf(true,true)
    if bufname then vim.api.nvim_buf_set_name(buf,bufname) end

    if not vim.o.guicursor:find('a:Cursor') then
        vim.opt.guicursor:append('a:Cursor')
    end

    local needs_remapping={}
    for _,m in ipairs(vim.api.nvim_get_keymap('i')) do
        if m.buffer==1 then
            vim.keymap.del('i',m.lhs,{buffer=buf})
        end
        needs_remapping[key_get_first(m.lhs)]=true
    end
    for k,_ in pairs(needs_remapping) do
        vim.keymap.set('i',k,k,{noremap=true,nowait=true,buffer=buf})
    end

    local au

    local function input(data)
        draw(buf,pass_params(buf,on_input,data))
    end
    local redraw=function ()
        if not vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_del_autocmd(au) return end
        draw(buf,pass_params(buf,on_input))
    end
    au=vim.api.nvim_create_autocmd('WinResized',{callback=redraw})

    local c_bslash_on=false
    vim.on_key(function(key)
        if vim.api.nvim_get_current_buf()~=buf then return end
        if vim.fn.mode()~='i' then return end
        if c_bslash_on then
            if key==vim.keycode('<C-n>') then
                vim.cmd.stopinsert()
                return ''
            end
            c_bslash_on=false
        elseif key==vim.keycode('<C-\\>') then
            c_bslash_on=true
            return ''
        end
        input(key)
        return ''
    end,vim.api.nvim_create_namespace('small-dff2'))

    vim.api.nvim_set_current_buf(buf)
    if startinsert then
        vim.cmd.startinsert()
    end

    redraw()

    return function (lines,pos,extra) draw(buf,lines,pos,extra) end
end
vim.cmd.vsplit()
local lines={}
M.open(function (k)
    if k.data then
        if #lines>=k.height then
            table.remove(lines,1)
        end
        table.insert(lines,vim.inspect(k.data))
    end
    return lines
end)
return M
