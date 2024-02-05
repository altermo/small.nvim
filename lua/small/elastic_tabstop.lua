local M={ns=vim.api.nvim_create_namespace'small_elastic_tabstop'}
function M.create_tabs(buf)
    local tabstop=vim.bo[buf].tabstop
    local col=0
    local tab_pos={}
    local virt_off={}
    local tabs={}
    local has_tab=true
    while col<=1000 and has_tab do
        has_tab=false
        col=col+1
        local current=nil
        for row=1,vim.api.nvim_buf_line_count(buf) do
            local line=vim.api.nvim_buf_get_lines(buf,row-1,row,false)[1]
            local idx=line:find('\t',(tab_pos[row] or 0)+1)
            if not idx then
                current=nil
                goto continue
            end
            if current==nil then current={-1} end
            virt_off[row]=virt_off[row] or {{0}}
            local virt=table.remove(virt_off[row],1)[1]
            local off=virt-(tab_pos[row] or 0)-(col>1 and 1 or 0)
            local t=(-(off+idx))%tabstop+1
            off=off+t
            if current[1]<idx+off then
                current[1]=idx+off
            end
            tabs[row]=(tabs[row] or {})
            tabs[row][col]={idx,current}
            has_tab=true
            tab_pos[row]=idx
            table.insert(virt_off[row],current)
            ::continue::
        end
    end
    return tabs
end
function M.setup()
    local function char(str,i) return vim.fn.strcharpart(str,i-1,1) end
    vim.api.nvim_set_decoration_provider(M.ns,{on_buf=function (_,buf)
        local listtab='  '
        vim.api.nvim_buf_call(buf,function ()
            if not vim.o.list then return end
            listtab=vim.opt_local.listchars:get().tab
        end)
        local tabstop=vim.bo.tabstop
        vim.api.nvim_buf_clear_namespace(0,M.ns,0,-1)
        local caches={[buf]=M.create_tabs(buf)}
        for row=1,vim.api.nvim_buf_line_count(buf) do
            local taboff=0
            local virtoff=0
            for _,c in ipairs(caches[buf][row] or {}) do
                local len=c[2][1]-(c[1]+virtoff)
                local t=(-(c[1]+taboff))%tabstop+1
                local col=c[1]
                virtoff=virtoff+len-1
                taboff=taboff+t-1
                local text
                if vim.api.nvim_strwidth(listtab)==3 then
                    text=(len==1 and '' or char(listtab,1))..char(listtab,2):rep(len-2)..char(listtab,3)
                else
                    text=char(listtab,1)..char(listtab,2):rep(len-1)
                end
                vim.api.nvim_buf_set_extmark(buf,M.ns,row-1,col-1,{
                    virt_text={{text:sub(1,t),'Whitespace'}},
                    virt_text_pos='overlay',
                })
                vim.api.nvim_buf_set_extmark(buf,M.ns,row-1,col,{
                    virt_text={{text:sub(t+1),'Whitespace'}},
                    virt_text_pos='inline',
                })
            end
        end
    end})
end
if vim.dev then
    M.setup()
end
return M
