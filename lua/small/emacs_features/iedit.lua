local M={ns=vim.api.nvim_create_namespace'small_iedit'}
function M.find_all(text)
    local t=table.concat(text,'\n')
    local buffer=table.concat(vim.api.nvim_buf_get_lines(0,0,-1,true),'\n')
    local ret={}
    local byte=buffer:find(t,0,true)
    while byte do
        local rows=vim.fn.byte2line(byte)
        local cols=byte-vim.fn.line2byte(rows)
        local rowe=rows+#text-1
        local cole=(#text==1 and cols or 0)+#text[#text]
        table.insert(ret,{rows-1,cols,rowe-1,cole})
        byte=buffer:find(t,byte+1,true)
    end
    return ret
end
function M.clear()
    vim.api.nvim_buf_clear_namespace(0,M.ns,0,-1)
    M.text=nil
end
function M._create_extmark(rows,cols,rowe,cole,id)
    vim.api.nvim_buf_set_extmark(0,M.ns,rows,cols,{
        end_row=rowe,
        end_col=cole,
        hl_group='IncSearch',
        id=id,
        end_right_gravity=true,
        right_gravity=false,
    })
end
function M.select(range)
    M.clear()
    local text=vim.api.nvim_buf_get_text(0,range[1],range[2],range[3],range[4],{})
    M.text=table.concat(text,'\n')
    local all=M.find_all(text)
    for _,r in ipairs(all) do
        M._create_extmark(r[1],r[2],r[3],r[4])
    end
end
function M._update()
    for _,v in ipairs(vim.api.nvim_buf_get_extmarks(0,M.ns,0,-1,{details=true})) do
        local s,text=pcall(vim.api.nvim_buf_get_text,0,v[2],v[3],v[4].end_row,v[4].end_col,{})
        if not s then return end
        local t=table.concat(text,'\n')
        if t~=M.text then
            M.text=t
            for _,i in ipairs(vim.api.nvim_buf_get_extmarks(0,M.ns,0,-1,{details=true})) do
                vim.api.nvim_buf_set_text(0,i[2],i[3],i[4].end_row,i[4].end_col,text)
                M._create_extmark(i[2],i[3],i[2]+#text-1,(#text==1 and i[3] or 0)+#text[#text],i[1])
            end
            return
        end
    end
end
function M.visual()
    local pos1=vim.fn.getpos('v')
    local pos2=vim.fn.getpos('.')
    if pos1[2]>pos2[2] or (pos1[2]==pos2[2] and pos1[3]>pos2[3]) then
        pos1,pos2=pos2,pos1
    end
    pos1={pos1[2]-1,pos1[3]-1}
    pos2={pos2[2]-1,pos2[3]}
    M.select({pos1[1],pos1[2],pos2[1],pos2[2]})
end
function M.setup()
    vim.api.nvim_create_autocmd(
        {'TextChanged','TextChangedI','TextChangedP'},
        {callback=M._update,group=vim.api.nvim_create_augroup('small_iedit',{})}
    )
end
if vim.dev then
    M.clear()
    vim.keymap.set('x','gi',M.visual)
    M.setup()
end
return M
