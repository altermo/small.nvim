local M={}
M.ns=vim.api.nvim_create_namespace('small_debugger')
if not _G._ERROR then _G._ERROR=_G.error end
function M.get_traceback_data(level)
    local ret={}
    while true do
        local info=debug.getinfo(level,'nSlufL')
        if not info then break end
        table.insert(ret,info)
        level=level+1
    end
    return ret
end
function M.create_traceback_buf(traceback,win,mes,default_file)
    local buf=vim.api.nvim_create_buf(false,true)
    vim.api.nvim_set_option_value('bufhidden','wipe',{buf=buf})
    if win then vim.api.nvim_win_set_buf(win,buf) end
    local places={}
    local function nw(text) return function () vim.notify(text) end end
    local function file_open_wrapp(file,row)
        return function ()
            vim.cmd.vnew(file)
            if row then vim.cmd(tostring(row)) end
        end
    end
    vim.api.nvim_buf_set_lines(buf,0,-1,false,{'Press <CR> on line to open file'})
    table.insert(places,nw("Can't enter an instruction"))
    vim.api.nvim_buf_set_lines(buf,1,1,false,{'The error is: '..mes})
    table.insert(places,nw("Can't enter an error message"))
    vim.api.nvim_buf_set_lines(buf,2,2,false,{''})
    table.insert(places,nw("Can't enter a blank line"))
    for _,v in ipairs(traceback) do
        local line
        local enter
        local file=v.source:gsub('^@','')
        if file==':source (no file)' and default_file then file=default_file end
        if v.what=='C' then
            line='C:'..v.name
            enter=nw("Can't enter lua-c code")
        elseif v.what=='main' and file==':lua' then
            line='lua:internal'
            enter=nw("Can't enter lua internal code")
        elseif v.what=='main' then
            line='file:'..file
            enter=file_open_wrapp(file)
        elseif vim.startswith(v.source,'@vim/') then
            line='vim:'..v.name..':'..file
            enter=function ()
                vim.cmd.help('vim.'..v.name)
            end
        else
            line=v.what..':'..v.currentline..':'..file
            enter=file_open_wrapp(file,v.currentline)
        end
        table.insert(places,enter)
        vim.api.nvim_buf_set_lines(buf,-1,-1,false,{line})
    end
    vim.api.nvim_set_option_value('modifiable',false,{buf=buf})
    vim.keymap.set('n','<cr>',function() places[vim.fn.line('.')]() end,{buffer=buf})
end
---@param message any
---@param level?  integer
function M.error(message,level)
    local traceback=M.get_traceback_data(3)
    for _,i in ipairs(traceback) do
        if i.what=='C' and i.name=='pcall' then
            _G._ERROR(message,level)
        end
    end
    message=message or 'nil'
    local guess_file=vim.fn.expand'%'
    ---@diagnostic disable-next-line: cast-local-type
    if guess_file=='' then guess_file=nil end
    vim.on_key(function(key)
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.on_key(nil,M.ns)
        if key~='y' then return end
        vim.api.nvim_input'<esc>'
        vim.cmd.vsplit()
        M.create_traceback_buf(traceback,vim.api.nvim_get_current_win(),message,guess_file)
    end,M.ns)
    _G._ERROR(message..'\n\n#### press y to start debugger ####\n',level)
end
function M.overide_error()
    rawset(_G,'error',M.error)
end
if vim.dev then
    M.overide_error()
    error(1)
end
return M
