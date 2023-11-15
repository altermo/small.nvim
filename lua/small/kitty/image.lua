local M={}
local w=io.write
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
    vim.system({'convert',source,M.tempfile},{},function(out)
        if out.code~=0 then
            error('convertion to png faild with exit code '..out.code)
        end
        fn(M.tempfile,unpack(args))
    end)
end
function M.send_png_packet(payload,last,x,y,width,height)
    if x and y then w('\x1b['..y..';'..x..'H') end
    w('\x1b_G')
    local cmd={'f=100','a=T',m=last and '1' or '0'}
    if height then table.insert(cmd,'r='..height) end
    if width then table.insert(cmd,'c='..width) end
    w(table.concat(cmd,','))
    if payload then w(';'..payload) end
    w('\x1b\\')
end
function M.render(source,x,y,width,height)
    if not M.is_png(source) then
        M.make_into_png(source,M.render,x,y,width,height)
        return
    end
    local fd=io.open(source,'r')
    if not fd then error('failed to open image file') end
    local data=vim.base64.encode(fd:read('*a'))
    local chunk
    while data~='' do
        chunk,data=data:sub(1,0x1000),data:sub(0x1000)
        local last=data==''
        M.send_png_packet(chunk,last,x,y,width,height)
    end
end
function M.clear()
    w('\x1b_Ga=d\x1b\\')
end
if vim.dev then
    M.clear()
    local source=vim.api.nvim_get_runtime_file('lua/small/kitty/test-image.jpg',false)[1]
    M.render(source,2,2,10,10)
end
return M
