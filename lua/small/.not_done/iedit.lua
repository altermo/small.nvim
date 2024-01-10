local M={ns=vim.api.nvim_create_namespace'small_iedit',marks={}}
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
    M.marks={}
    M.text=nil
end
function M.select(range)
    M.clear()
    local text=vim.api.nvim_buf_get_text(0,range[1],range[2],range[3],range[4],{})
    M.text=table.concat(text,'\n')
    local all=M.find_all(text)
    for _,r in ipairs(all) do
        table.insert(M.marks,vim.api.nvim_buf_set_extmark(0,M.ns,r[1],r[2],{
            end_row=r[3],
            end_col=r[4],
            hl_group='IncSearch'
        }))
    end
end
function M._update()
    for _,v in ipairs(M.marks) do
        local m=vim.api.nvim_buf_get_extmark_by_id(0,M.ns,v,{details=true}) --[[@as any]]
        local text=vim.api.nvim_buf_get_text(0,m[1],m[2],m[3].end_row,m[3].end_col,{})
        local t=table.concat(text,'\n')
        if t~=M.text then
            M.text=t
            for _,i in ipairs(M.marks) do
                local c=vim.api.nvim_buf_get_extmark_by_id(0,M.ns,i,{details=true}) --[[@as any]]
                vim.api.nvim_buf_set_text(0,c[1],c[2],c[3].end_row,c[3].end_col,text)
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
if vim.dev then
    M.clear()
    vim.keymap.set('x','gi',M.visual)
    vim.api.nvim_create_autocmd(
        {'TextChanged','TextChangedI','TextChangedP'},
        {callback=M._update,group=vim.api.nvim_create_augroup('small_iedit',{})}
    )
end
return M
