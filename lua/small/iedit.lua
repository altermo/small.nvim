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
        byte=buffer:find(t,byte+#text+1,true)
    end
    return ret
end
function M.clear()
    vim.api.nvim_buf_clear_namespace(0,M.ns,0,-1)
    M.text=nil
end
function M._create_extmark(rows,cols,rowe,cole,id)
    return vim.api.nvim_buf_set_extmark(0,M.ns,rows,cols,{
        end_row=rowe,
        end_col=cole,
        hl_group='IncSearch',
        id=id,
        end_right_gravity=true,
        right_gravity=false,
    })
end
function M.select_all(range)
    M._setup()
    M.clear()
    local text=vim.api.nvim_buf_get_text(0,range[1],range[2],range[3],range[4],{})
    M.text=table.concat(text,'\n')
    local all=M.find_all(text)
    for _,r in ipairs(all) do
        M._create_extmark(r[1],r[2],r[3],r[4])
    end
end
function M.select(range)
    M._setup()
    M.clear()
    local text=vim.api.nvim_buf_get_text(0,range[1],range[2],range[3],range[4],{})
    M.text=table.concat(text,'\n')
    local all=M.find_all(text)
    local current_idx
    for k,v in ipairs(all) do
        if v[1]==range[1] and v[2]==range[2] and v[3]==range[3] and v[4]==range[4] then
            current_idx=k
            break
        end
    end
    local select_idx=current_idx
    local ns=vim.api.nvim_create_namespace('small_iedit_select')
    local id
    local function set(idx)
        local r=all[idx]
        id=vim.api.nvim_buf_set_extmark(0,ns,r[1],r[2],{
            end_row=r[3],
            end_col=r[4],
            id=id,
            hl_group='CurSearch',
            end_right_gravity=true,
            right_gravity=false,
        })
    end
    local function hash(r)
        return table.concat(r,';')
    end
    local select_all
    local count=0
    local cursor=vim.api.nvim_win_get_cursor(0)
    local done={}
    vim.cmd'norm! \x1b'
    local function toggle(r)
        if done[hash(r)] then
            vim.api.nvim_buf_del_extmark(0,M.ns,done[hash(r)])
            count=count-1
            done[hash(r)]=nil
        else
            done[hash(r)]= M._create_extmark(r[1],r[2],r[3],r[4])
            count=count+1
        end
    end
    while true do
        set(select_idx)
        print('q -> done  <esc>/<cr> -> select&done  n -> toggle&next  p -> toggle&prev  N -> next  P -> prev  a -> all')
        local r=all[select_idx]
        vim.api.nvim_win_set_cursor(0,{r[1]+1,r[2]})
        vim.cmd'norm! zz'
        vim.cmd.redraw()
        local char=vim.fn.getcharstr()
        if char=='q' then break
        elseif char=='\r' or char=='\x1b' then
            if not done[hash(r)] then toggle(r) end
            break
        elseif char=='a' then select_all=true break
        elseif char=='n' or char=='N' then
            if char=='n' then toggle(r) end
            select_idx=select_idx%#all+1
        elseif char=='p' or char=='P' then
            if char=='p' then toggle(r) end
            select_idx=(select_idx-2)%#all+1
        end
        if count==#all then break end
    end
    print('\n')
    vim.api.nvim_win_set_cursor(0,cursor)
    vim.api.nvim_buf_clear_namespace(0,ns,0,-1)
    if select_all then
        M.select_all(range)
    end
end
function M._update()
    for _,v in ipairs(vim.api.nvim_buf_get_extmarks(0,M.ns,0,-1,{details=true})) do
        local s,text=pcall(vim.api.nvim_buf_get_text,0,v[2],v[3],v[4].end_row,v[4].end_col,{})
        if not s then return end
        local t=table.concat(text,'\n')
        if t~=M.text then
            M.text=t
            local neq=false
            for _,i in ipairs(vim.api.nvim_buf_get_extmarks(0,M.ns,0,-1,{details=true})) do
                for k,j in ipairs(vim.api.nvim_buf_get_text(0,i[2],i[3],i[4].end_row,i[4].end_col,{})) do
                    if text[k]~=j or neq then neq=true break end
                end
                if neq then
                    vim.api.nvim_buf_set_text(0,i[2],i[3],i[4].end_row,i[4].end_col,text)
                    M._create_extmark(i[2],i[3],i[2]+#text-1,(#text==1 and i[3] or 0)+#text[#text],i[1])
                end
            end
            if neq then vim.cmd.undojoin() end
            return
        end
    end
end
function M.visual_all()
    local pos1=vim.fn.getpos('v')
    local pos2=vim.fn.getpos('.')
    if pos1[2]>pos2[2] or (pos1[2]==pos2[2] and pos1[3]>pos2[3]) then
        pos1,pos2=pos2,pos1
    end
    pos1={pos1[2]-1,pos1[3]-1}
    pos2={pos2[2]-1,pos2[3]}
    M.select_all({pos1[1],pos1[2],pos2[1],pos2[2]})
end
function M.visual_select()
    local pos1=vim.fn.getpos('v')
    local pos2=vim.fn.getpos('.')
    if pos1[2]>pos2[2] or (pos1[2]==pos2[2] and pos1[3]>pos2[3]) then
        pos1,pos2=pos2,pos1
    end
    pos1={pos1[2]-1,pos1[3]-1}
    pos2={pos2[2]-1,pos2[3]}
    M.select({pos1[1],pos1[2],pos2[1],pos2[2]})
end
function M._setup()
    if M._ then return end
    M._=true
    --TODO: make it activate other TextChanged autocmds (without activating itself)
    vim.api.nvim_create_autocmd(
        {'TextChanged','TextChangedI','TextChangedP'},
        {callback=M._update,group=vim.api.nvim_create_augroup('small_iedit',{})}
    )
end
if vim.dev then
    M.clear()
    vim.keymap.set('x','gC',M.clear)
    vim.keymap.set('x','gI',M.visual_all)
    vim.keymap.set('x','gi',M.visual_select)
end
return M
