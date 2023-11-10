local I={}
local M={I=I}
M.enter='\r'
M.backspace='\127'
M.escape='\x1b'
---@param buf number
---@param lines? string[]|true
M.draw=function (buf,lines,...)
    _=...
    if lines==true then vim.api.nvim_buf_delete(buf,{force=true}) return end
    vim.api.nvim_buf_set_lines(buf,0,-1,false,lines or {})
end
---@param buf number
---@return number[]
function M.I.buf_get_wins(buf)
    return vim.tbl_filter(function (win) return vim.api.nvim_win_get_buf(win)==buf end,vim.api.nvim_list_wins())
end
---@param buf number
---@param fn fun(in:small.mode.on_redraw_param):string[]|true?,number[]?,string?
---@param data any
---return string[]?|true,number[]?,string?
function M.pass_params(buf,fn,data)
    local wins=M.I.buf_get_wins(buf)
    local height=math.max(0,unpack(vim.tbl_map(function (win) return vim.api.nvim_win_get_height(win) end,wins)))
    local width=math.max(0,unpack(vim.tbl_map(function (win) return vim.api.nvim_win_get_width(win) end,wins)))
    return fn({height=height,width=width,wins=wins,chan=buf,buf=buf,data=data})
end
---@param on_input fun(in:small.mode.on_redraw_param):string[]|true?,number[]?,string?
---@param _? boolean
---@param bufname? string
---@return fun(lines?:string[]|true,pos?:number[],extra?:string)
function M.open(on_input,bufname,_)
    local buf=vim.api.nvim_create_buf(true,true)
    if bufname then vim.api.nvim_buf_set_name(buf,bufname) end
    local function input()
        vim.cmd.redraw()
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(buf) then return end
            local key=vim.fn.getcharstr()
            local ret={M.pass_params(buf,on_input,key)}
            if #ret==0 then return end
            M.draw(buf,unpack(ret))
            input()
        end)
    end
    local redraw=function ()
        M.draw(buf,M.pass_params(buf,on_input))
        vim.cmd.redraw()
    end
    M.draw(buf,M.pass_params(buf,on_input))
    vim.cmd.redraw()
    vim.api.nvim_create_autocmd('WinResized',{callback=redraw,buffer=buf})
    vim.api.nvim_create_autocmd('BufEnter',{callback=input,buffer=buf})
    vim.api.nvim_set_current_buf(buf)
    return function (lines,pos,extra) M.draw(buf,lines,pos,extra) end
end
if vim.dev then
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
end
return M
