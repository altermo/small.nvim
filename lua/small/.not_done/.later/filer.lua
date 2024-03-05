--[[

--]]
local M={conf={}}
M.maps={
    a=function ()
        local file=M.getcurrent()
        vim.fn.input('>',file..vim.keycode'<Left>':rep(#file-#vim.fn.fnamemodify(file,':r')))
    end,
    A=function ()
        local file=M.getcurrent()
        vim.fn.input('>',file)
    end,
    I=function ()
        local file=M.getcurrent()
        vim.fn.input('>',file..vim.keycode'<Left>':rep(#file))
    end,
}
function M.getcurrent()
    return vim.fn.getline'.'
end
---@param errstr string
function M.error(errstr,...)
    vim.notify(errstr:format(...),vim.log.levels.ERROR)
end
---@param path string
---@return boolean
function M.is_binary(path)
    local file=assert(io.open(path,'rb'),('File %s is not valid'):format(path))
    local text=file:read(1024)
    if text:find('\0') then
        return true
    end
    for _,v in ipairs({'%PDF','\x89PNG'}) do
        if text:sub(1,#v)==v then
            return true
        end
    end
    return false
end
---@param path string
---@param opt table
function M.open(path,opt)
    path=vim.fn.fnamemodify(path,':p')
    if vim.fn.isdirectory(path)==1 then
    elseif vim.fn.filereadable(path)==1 then
        M.open(vim.fs.dirname(path),setmetatable({select=path},{__index=opt}))
        return
    else
        M.error('Path %s is invalid',path)
        return
    end
    if opt.preopencmd then
        opt.preopencmd()
    end
    local buf=vim.api.nvim_create_buf(true,true)
    vim.bo[buf].bufhidden='wipe'
    vim.bo[buf].filetype='filer'
    vim.api.nvim_buf_set_name(buf,('filer://%s//%s:filer'):format(path:gsub(vim.pesc(vim.env.HOME),'~'),buf))
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf,0,-1,true,vim.fn.readdir(path))
    for k,v in pairs(M.maps) do
        vim.api.nvim_buf_set_keymap(buf,'n',k,'',{callback=v,nowait=true})
    end
end
if vim.dev then
    M.open('.',{preopencmd=vim.cmd.tabnew})
end
return M
