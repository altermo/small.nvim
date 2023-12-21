local M={}
function M.buf_get_file(buf)
    local filepath=vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf),':p')
    if vim.fn.filereadable(filepath)~=1 then return end
    return filepath
end
function M.buf_get_lfile(buf)
    return M.file_to_lfile(M.buf_get_file(buf))
end
function M.file_to_lfile(file)
    return file:gsub(vim.fn.getcwd(),'.')
end
M.marked_buf={}
function M.get_buf_list(key)
    return vim.iter(vim.api.nvim_list_bufs()):filter(vim.api.nvim_buf_is_loaded):filter(function(v)
        local file=M.buf_get_file(v)
        return file and ((not key) or key==vim.fn.fnamemodify(file,':t'):sub(1,1))
    end):rev():totable()
end
function M.get_file(key)
    if M.marked_buf[key] then return {M.marked_buf[key]} end
    if M.get_buf_list(key) then return M.get_buf_list(key) end
end
function M.mark_buf(key) M.marked_buf[key]=vim.api.nvim_get_current_buf() end
function M.unmark_buf(key) M.marked_buf[key]=nil end
function M.select(key)
    require'small.lib.select'(vim.tbl_map(M.buf_get_lfile,M.get_buf_list(key)),{},function (file) vim.cmd.edit(file) end)
end
function M.run()
    local keys={}
    for _,buf in pairs(M.get_buf_list()) do
        local file=assert(M.buf_get_file(buf))
        local key=vim.fn.fnamemodify(file,':t'):sub(1,1)
        keys[key]=M.get_file(key)
    end
    local buf=vim.api.nvim_create_buf(false,true)
    vim.bo[buf].bufhidden='wipe'
    vim.api.nvim_buf_set_lines(buf,0,-1,false,{'<cr>  : mark buffer','<bs>  : unmark buffer','<tab> : search buffer files',''})
    for key,bufs in vim.spairs(keys) do
        vim.api.nvim_buf_set_lines(buf,-1,-1,false,{(M.marked_buf[key] and '#' or '')..key..' : '..table.concat(vim.tbl_map(M.buf_get_lfile,bufs),' ;; ')})
    end
    local win=vim.api.nvim_open_win(buf,false,{
        relative='editor',width=vim.o.columns>20 and vim.o.columns-20 or 10,height=vim.o.lines>20 and vim.o.lines-20 or 10,col=10,row=10,
        focusable=false,style='minimal',noautocmd=true
    })
    vim.api.nvim_buf_set_lines(buf,-1,-1,false,{'* : find files starting with *'})
    vim.cmd.redraw()
    local char=vim.fn.getcharstr()
    vim.api.nvim_win_close(win,true)
    if char=='\r' then M.mark_buf(vim.fn.getcharstr())
    elseif char=='\x80kb' then M.unmark_buf(vim.fn.getcharstr())
    elseif char=='\t' then M.select()
    elseif char~='\x1b' then
        if keys[char] then
            keys[char]=vim.tbl_filter(function(x) return x~=vim.api.nvim_get_current_buf() end,keys[char])
            if #keys[char]==1 then vim.cmd.buf(keys[char][1])
            else M.select(char) end
        elseif vim.regex('\\v[a-z.-_]'):match_str(char) then
            require'small.lib.select'(vim.tbl_map(M.file_to_lfile,vim.fs.find(function (name,path)
                return name:sub(1,1)==char and not path:sub(#vim.fn.getcwd()):match('/%.')
            end,{type='file',limit=math.huge})),{},function (file)
                    if file then vim.api.nvim_buf_call(0,function () vim.cmd.edit(file) end) end
                end)
        end
    end
end
if vim.dev then M.run() end
return M
