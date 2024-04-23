local M={}
--TODO: each N seconds, run the function for some rows and cache the result (e.g. pre calculate the results)
--TODO: treesitter changedtree
function M.create_cache(buf,fn)
    local detach
    local cache={}
    for i=1,vim.api.nvim_buf_line_count(buf) do
        table.insert(cache,i,false)
    end
    vim.api.nvim_buf_attach(buf,false,{
        on_lines=function (_,_,_,first,last,newlast)
            if detach then return true end
            --TODO: test that it actually works
            if last<newlast then
                for i=first,last do
                    cache[i]=false
                end
                for i=last+1,newlast do
                    table.insert(cache,i,false)
                end
            else
                for i=first,newlast do
                    cache[i]=false
                end
                for i=newlast+1,last do
                    table.remove(cache,i)
                end
            end
        end
    })
    return function (row,...)
        local ret={fn(row,...)}
        cache[row]=ret
        return unpack(ret)
    end,function () detach=true end
end
return M
