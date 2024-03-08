local M={path='/tmp/plugins.json'}
function M.cache_valid()
    return vim.fn.filereadable(M.path)==1
end
function M.get_cache()
    local file=assert(io.open(M.path,'r'))
    local content=assert(file:read('*a'))
    file:close()
    return vim.json.decode(content)
end
function M.create_cache(cb)
    vim.system({'curl','https://neovimcraft.com/db.json'},{},function (out)
        assert(out.code==0,'curl failed')
        local file=assert(io.open(M.path,'w'))
        file:write(out.stdout)
        file:close()
        if cb then vim.schedule_wrap(cb)(M.get_cache()) end
    end)
end
function M.get(cb)
    if M.cache_valid() then
        return cb(M.get_cache())
    end
    M.create_cache(cb)
end
return M.get,M
