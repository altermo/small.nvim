local M={ns=vim.api.nvim_create_namespace'small_luay'}
function M.refresh()
    if not M.buf then return end
    if not vim.api.nvim_buf_is_valid(M.buf) then return end
    local lines=table.concat(vim.api.nvim_buf_get_lines(M.buf,0,-1,false),'\n')
    local f,errmsg=loadstring('\n'..lines)
    vim.api.nvim_buf_clear_namespace(M.buf,M.ns,0,-1)
    if not f or errmsg then
        if not errmsg then return end
        errmsg:gsub('^.-:(.-): (.*)$',function (n,msg)
            vim.api.nvim_buf_set_extmark(M.buf,M.ns,assert(tonumber(n))-2,0,{virt_text={{msg,'ErrorMsg'}}})
        end)
        return
    end
    local output=vim.defaulttable(function () return {} end)
    setfenv(f,setmetatable({
        print=function (...)
            if select('#',...)==0 then return end
            local line=debug.getinfo(2,'l').currentline-2
            if #output[line]>100 then return end
            vim.list_extend(output[line],vim.tbl_map(vim.inspect,{...}))
        end
    },{__index=_G}))
    if not xpcall(f,function (msg)
        local line=debug.getinfo(2,'l').currentline-2
        if line<0 then
            line=debug.getinfo(3,'l').currentline-2
        end
        if type(msg)~='string' then
            msg=vim.inspect(msg)
        else
            msg=msg:gsub('^.-:.-: ','')
        end
        vim.api.nvim_buf_set_extmark(M.buf,M.ns,line,0,{virt_text={{'Error: '..msg,'ErrorMsg'}}})
    end) then return end
    for row,v in pairs(output) do
        vim.api.nvim_buf_set_extmark(M.buf,M.ns,row,0,{virt_text={{table.concat(v,' | '),'Comment'}}})
    end
end
function M.run()
    M.buf=vim.api.nvim_create_buf(false,true)
    vim.api.nvim_buf_set_lines(M.buf,0,-1,false,{'---@diagnostic disable: undefined-global,unused-local,lowercase-global',''})
    vim.bo[M.buf].bufhidden='wipe'
    vim.bo[M.buf].filetype='lua'
    vim.api.nvim_create_autocmd({'TextChanged','TextChangedI','TextChangedP'},{buffer=M.buf,callback=M.refresh})
    vim.api.nvim_open_win(M.buf,true,{
        split='right'
    })
    vim.api.nvim_win_set_cursor(0,{2,0})
end
return M
