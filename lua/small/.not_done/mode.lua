---@class small.mode.on_redraw_param
---@field height number
---@field width number
---@field wins number[]
---@field chan number
---@field buf number
---@field data any

local I={}
local M={I=I}
---@param buf number
---@return number[]
function M.I.buf_get_wins(buf)
    return vim.tbl_filter(function (win) return vim.api.nvim_win_get_buf(win)==buf end,vim.api.nvim_list_wins())
end
---@param chan number
---@param fn fun(in:small.mode.on_redraw_param):string[]?,number[]?,string?
---@param data any
---return string[]?,number[]?,string?
function M.pass_params(chan,fn,data)
    local buf=vim.api.nvim_get_chan_info(chan).buffer
    if not buf then return end
    local wins=M.I.buf_get_wins(buf)
    local height=math.max(unpack(vim.tbl_map(function (win) return vim.api.nvim_win_get_height(win) end,wins)))
    local width=math.max(unpack(vim.tbl_map(function (win) return vim.api.nvim_win_get_width(win) end,wins)))
    return fn({height=height,width=width,wins=wins,chan=chan,buf=buf,data=data})
end
---@param chan number
---@param lines? string[]
---@param pos? number[]
---@param extra? string
function M.draw(chan,lines,pos,extra)
    local buf=vim.api.nvim_get_chan_info(chan).buffer
    if not buf then return end
    local wins=M.I.buf_get_wins(buf)
    local height=math.max(unpack(vim.tbl_map(function (win) return vim.api.nvim_win_get_height(win) end,wins)))
    local width=math.max(unpack(vim.tbl_map(function (win) return vim.api.nvim_win_get_width(win) end,wins)))
    for row,line in ipairs(lines or {}) do
        if row>height then break end
        vim.api.nvim_chan_send(chan,'\x1b['..row..';1H')
        vim.lg(line:sub(1,width))
        vim.api.nvim_chan_send(chan,line:sub(1,width))
    end
    if pos then
        vim.api.nvim_chan_send(chan,'\x1b['..pos[1]..';'..pos[2]..'H')
    else
        vim.api.nvim_chan_send(chan,'\x1b[?25l')
    end
    if extra then vim.api.nvim_chan_send(chan,extra) end
end
---@param on_input fun(in:small.mode.on_redraw_param):string[]?,number[]?,string?
function M.open_mode(on_input)
    local buf=vim.api.nvim_create_buf(true,true)
    vim.api.nvim_buf_set_lines(buf,0,-1,false,{'a'})
    vim.bo[buf].bufhidden='wipe'
    local chan
    local au
    local function input(_,_,_,data)
        local ret={M.pass_params(chan,on_input,data)}
        if #ret==0 then return end
        vim.api.nvim_chan_send(chan,'\x1b[2J\x1b[H')
        M.draw(chan,unpack(ret))
    end
    local redraw=function ()
        if not vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_del_autocmd(au) return end
        if chan then vim.api.nvim_chan_send(chan,'\x1b[2J\x1b[2H') end
        chan=vim.api.nvim_open_term(buf,{on_input=vim.schedule_wrap(input)})
        M.draw(chan,M.pass_params(chan,on_input))
    end
    au=vim.api.nvim_create_autocmd('WinResized',{callback=redraw})
    vim.api.nvim_set_current_buf(buf)
end
function M.clear(chan)
    vim.api.nvim_chan_send(chan,I.clear())
end
if vim.dev then
    vim.cmd.vsplit()
    local lines={}
    M.open_mode(function (k)
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