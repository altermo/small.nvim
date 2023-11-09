---@class small.mode.on_redraw_param
---@field height number
---@field width number
---@field wins number[]
---@field chan number
---@field buf number

local I={}
local M={I=I}
---@param buf number
---@return number[]
function M.I.buf_get_wins(buf)
    return vim.tbl_filter(function (win) return vim.api.nvim_win_get_buf(win)==buf end,vim.api.nvim_list_wins())
end
---@param chan number
---@param fn fun(in:small.mode.on_redraw_param):string[]?,number[]?,string?
function M.draw(chan,fn)
    local buf=vim.api.nvim_get_chan_info(chan).buffer
    if not buf then return end
    local wins=M.I.buf_get_wins(buf)
    local height=math.max(unpack(vim.tbl_map(function (win) return vim.api.nvim_win_get_height(win) end,wins)))
    local width=math.max(unpack(vim.tbl_map(function (win) return vim.api.nvim_win_get_width(win) end,wins)))
    local lines,pos,extra=fn({height=height,width=width,wins=wins,chan=chan,buf=buf})
    for row,line in ipairs(lines or {}) do
        if row>height then break end
        vim.api.nvim_chan_send(chan,'\x1b['..row..';1H')
        vim.api.nvim_chan_send(chan,line:sub(1,width))
    end
    if pos then
        vim.api.nvim_chan_send(chan,'\x1b['..pos[1]..';'..pos[2]..'H')
    else
        vim.api.nvim_chan_send(chan,'\x1b[?25l')
    end
    if extra then vim.api.nvim_chan_send(chan,extra) end
end
---@param on_input fun(in:(string|number)[])
---@param on_redraw fun(in:small.mode.on_redraw_param):string[]?,number[]?,string?
function M.open_mode(on_input,on_redraw)
    local buf=vim.api.nvim_create_buf(true,true)
    vim.api.nvim_buf_set_lines(buf,0,-1,false,{'a'})
    vim.bo[buf].bufhidden='wipe'
    local au
    local redraw=function ()
        if not vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_del_autocmd(au) return end
        local chan=vim.api.nvim_open_term(buf,{on_input=on_input})
        M.draw(chan,on_redraw)
    end
    au=vim.api.nvim_create_autocmd('WinResized',{callback=redraw})
    vim.api.nvim_set_current_buf(buf)
end
function M.clear(chan)
    vim.api.nvim_chan_send(chan,I.clear())
end
if vim.dev then
    vim.cmd.vsplit()
    M.open_mode(vim.pprint,function (k)
        local lines=vim.fn['repeat']({' '..('a'):rep(k.width-2)},k.height-1)
        lines[1]=''
        return lines,{2,2}
    end)
end
return M
