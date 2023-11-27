local M={}
M.stdout=vim.loop.new_tty(1,false)
if not M.stdout then error('failed to open stdout') end
function M.write(info)
    M.stdout:write(info)
end
---@return boolean?
function M.is_png(source)
    local fd=vim.uv.fs_open(source,'r',0)
    return fd and vim.uv.fs_read(fd,8,0)=='\x89PNG\r\n\x1a\n'
end
function M.make_into_png(source,fn,...)
    local args={...}
    if not vim.fn.executable('convert') then
        error('need `convert` binary to convert to png, pleas install library `imagemagick`')
    end
    if not M.tempfile then M.tempfile=vim.fn.tempname()..'.png' end
    local out=vim.system({'convert','-quality','10',source,M.tempfile}):wait()
    if out.code~=0 then
        error('convertion to png faild with exit code '..out.code)
    end
    vim.schedule_wrap(fn)(M.tempfile,unpack(args))
end
function M.send_png_packet(payload,last,first,width,height)
    M.write('\x1b_G')
    local cmd={'m='..(last and '0' or '1')}
    if first then
        table.insert(cmd,'a=T')
        table.insert(cmd,'f=100')
        if height then table.insert(cmd,'r='..height) end
        if width then table.insert(cmd,'c='..width) end
    end
    M.write(table.concat(cmd,','))
    if payload then M.write(';'..payload) end
    M.write('\x1b\\')
end
function M.chunckify(str)
    local ret={}
    for i=1,#str,0x1000 do
        table.insert(ret,(str:sub(i,i+0x1000-1):gsub('%s','')))
    end
    return ret
end
function M.render(source,x,y,width,height,win)
    if win then
        local row,col=unpack(vim.api.nvim_win_get_position(win))
        y,x=y+row,x+col
    end
    if not M.is_png(source) then
        M.make_into_png(source,M.render,x,y,width,height)
        return
    end
    local fd=io.open(source,'r')
    if not fd then error('failed to open image file') end
    local data=vim.base64.encode(fd:read('*a'))
    local chunks=M.chunckify(data)
    for k,chunk in ipairs(chunks) do
        if x and y then M.write('\x1b['..y..';'..x..'H') end
        M.send_png_packet(chunk,k==#chunks,k==1,width,height)
    end
end
function M.clear()
    M.write('\x1b_Ga=d\x1b\\')
end
if vim.dev then
    M.clear()
    local source=vim.api.nvim_get_runtime_file('lua/small/kitty/test-image.jpg',false)[1]
    M.render(source,2,2,10,10)
end
return M
