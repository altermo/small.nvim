---@class lbpr.data
---@field template string
---@field working_buf number
---@field code_buf number
---@field preview_buf number
---@field lines string[]

local M={}
M.I={
    buf_set_opt=function(buf,name,value)
        return vim.api.nvim_set_option_value(name,value,{buf=buf})
    end
}
---@param _ number buf
---@return string
M.template=function (_)
    return [[
local new_lst={}
---@diagnostic disable-next-line: undefined-global
for n,i in ipairs(Lines) do
    table.insert(new_lst,i)
end
return new_lst]]
end
---@param data lbpr.data
function M.setpreview(data)
    local win=vim.api.nvim_open_win(data.working_buf,false,{
        hide=true,noautocmd=true,focusable=false,
        width=1,height=1,
        relative='editor',
        col=1,row=1
    })
    vim.wo[win].diff=true
    local buf=vim.api.nvim_create_buf(true,true)
    M.I.buf_set_opt(buf,'bufhidden','wipe')
    M.I.buf_set_opt(buf,'buftype','acwrite')
    vim.api.nvim_buf_set_lines(buf,0,-1,false,data.lines)
    M.I.buf_set_opt(buf,'modifiable',false)
    M.I.buf_set_opt(buf,'filetype',vim.bo[data.working_buf].filetype)
    vim.api.nvim_set_current_buf(buf)
    vim.wo.diff=true
    vim.api.nvim_buf_set_name(buf,'lpbr-preview')
    vim.api.nvim_create_autocmd('BufWriteCmd',{callback=function ()
        M.save(data)
    end,buffer=buf})
    data.preview_buf=buf
end
---@param data lbpr.data
function M.save(data)
    local lines=vim.api.nvim_buf_get_lines(data.preview_buf,0,-1,false)
    vim.api.nvim_buf_set_lines(data.working_buf,0,-1,false,lines)
end
---@param data lbpr.data
function M.setcode(data)
    local buf=vim.api.nvim_create_buf(true,true)
    M.I.buf_set_opt(buf,'bufhidden','wipe')
    M.I.buf_set_opt(buf,'buftype','acwrite')
    M.I.buf_set_opt(buf,'filetype','lua')
    vim.api.nvim_buf_set_lines(buf,0,-1,true,vim.split(data.template,'\n'))
    vim.api.nvim_buf_set_name(buf,'lpbr-script')
    M.I.buf_set_opt(buf,'modified',false)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_create_autocmd('BufWriteCmd',{callback=function ()
        M.act_code(data)
    end,buffer=buf})
    data.code_buf=buf
end
---@param data lbpr.data
function M.act_code(data)
    M.I.buf_set_opt(data.code_buf,'modified',false)
    local code=vim.api.nvim_buf_get_lines(data.code_buf,0,-1,false)
    local f,errmsg=loadstring(table.concat(code, '\n'))
    if not f then error(errmsg) return end
    setfenv(f,setmetatable({Lines=data.lines},{__index=_G}))
    M.preview_set_code(data,f())
end
---@param data lbpr.data
---@param code string[]
function M.preview_set_code(data,code)
    M.I.buf_set_opt(data.preview_buf,'modifiable',true)
    vim.api.nvim_buf_set_lines(data.preview_buf,0,-1,false,code)
    M.I.buf_set_opt(data.preview_buf,'modifiable',false)
    M.I.buf_set_opt(data.preview_buf,'modified',false)
end
function M.run()
    local buf=vim.api.nvim_get_current_buf()
    local data={
        template=M.template(buf),
        working_buf=buf,
        lines=vim.api.nvim_buf_get_lines(buf,0,-1,false),
    }
    vim.cmd('tab split')
    vim.cmd.vsplit()
    M.setpreview(data)
    vim.cmd.wincmd('p')
    M.setcode(data)
end
if vim.dev then
    M.run()
end
return M
