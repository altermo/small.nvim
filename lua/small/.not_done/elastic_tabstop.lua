local M={ns=vim.api.nvim_create_namespace'small_elastic_tabstop'}
function M.setup()
    local caches
    local function run_cache(buf,row,_data)
        if not caches[buf] then caches[buf]={} end
        if caches[buf][row] then return end
        local cache={}
        caches[buf][row]=cache
        local line=vim.api.nvim_buf_get_lines(buf,row-1,row,false)[1]
        if not line or not line:find'\t' then return end
        _data=_data or {}
        local i
        local tabstop=vim.bo[buf].tabstop
        local tabs={}
        local virtoff=0
        while true do
            i=line:find('\t',(i or 0)+1)
            if not i then break end
            table.insert(tabs,{i+virtoff,(-(i+virtoff))%tabstop+1+i})
            virtoff=virtoff+(-(i+virtoff))%tabstop
        end
        local new_data={}
        for idx,tab in ipairs(tabs) do
            local data=_data[idx]
            if not data then
                data={tab[2]}
                table.insert(new_data,data)
            end
            if tab[2]>data[1] then data[1]=tab[2] end
            table.insert(cache,{tab[1],data})
        end
        run_cache(buf,row-1,new_data)
        run_cache(buf,row+1,new_data)
    end

    vim.api.nvim_set_decoration_provider(M.ns,{on_start=function() caches={} end,on_buf=function (_,buf)
        vim.api.nvim_buf_clear_namespace(buf,M.ns,0,-1)
        local tabstop=vim.bo[buf].tabstop
        for row=1,vim.api.nvim_buf_line_count(buf) do
            run_cache(buf,row)
            local virtoff=0
            for _,c in ipairs(caches[buf][row]) do
                local len=c[2][1]-c[1]
                local t=(-(c[1]+virtoff))%tabstop+1
                virtoff=virtoff-t-1
                local col=c[1]-virtoff
                vim.api.nvim_buf_set_extmark(buf,M.ns,row-1,col-1,{
                    virt_text={{('a'):rep(t)}},
                    virt_text_pos='overlay',
                })
                vim.api.nvim_buf_set_extmark(buf,M.ns,row-1,col,{
                    virt_text={{('b'):rep(len-t)}},
                    virt_text_pos='inline',
                })
            end
        end
    end})
end
if vim.dev then
    M.setup()
    --	a	1
    ----jdlhfsajdfhalsjfdhalfkdjahlfkjhafladf	bfasldhfa	2
end
return M
