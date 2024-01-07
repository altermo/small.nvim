local M={
    ns=vim.api.nvim_create_namespace'small_cursor',
    data={},
    conf={},
}
function M.create_cursor()
    local row,col=unpack(vim.api.nvim_win_get_cursor(0))
    local buf=vim.api.nvim_get_current_buf()
    local id=vim.api.nvim_buf_set_extmark(0,M.ns,row-1,col,{id=math.max(0,unpack(vim.tbl_keys(M.data)))+1})
    M.data[id]={buf=buf}
end
function M.buf_get_cursors(buf,start,end_)
    start=start or 0
    end_=end_ or -1
    return vim.api.nvim_buf_get_extmarks(buf,M.ns,start,end_,{})
end
function M.goto_next_cursor(create_cursor)
    local curbuf=vim.api.nvim_get_current_buf()
    local row,col=unpack(vim.api.nvim_win_get_cursor(0))
    local pos=vim.api.nvim_buf_get_extmarks(curbuf,M.ns,{row-1,col+1},-1,{})[1]
    if not pos then
        for _,buf in ipairs(vim.api.nvim_list_bufs()) do
            if buf>curbuf then
                pos=M.buf_get_cursors(buf)[1]
                if pos then break end
            end
        end
    end
    if not pos then
        for _,buf in ipairs(vim.api.nvim_list_bufs()) do
            if buf<curbuf then
                pos=M.buf_get_cursors(buf)[1]
                if pos then break end
            end
        end
    end
    if not pos then
        pos=vim.api.nvim_buf_get_extmarks(0,M.ns,0,-1,{})[1]
    end
    if not pos then return end
    if create_cursor then M.create_cursor() end
    if curbuf~=M.data[pos[1]].buf then
        vim.api.nvim_set_current_buf(M.data[pos[1]].buf)
    end
    vim.api.nvim_win_set_cursor(0,{pos[2]+1,pos[3]})
    M.del_cursor(pos[1])
end
function M.goto_prev_cursor(create_cursor)
    local curbuf=vim.api.nvim_get_current_buf()
    local row,col=unpack(vim.api.nvim_win_get_cursor(0))
    local pos=table.remove(vim.api.nvim_buf_get_extmarks(0,M.ns,0,{row-1,col-1},{}))
    if not pos then
        for _,buf in ipairs(vim.fn.reverse(vim.api.nvim_list_bufs())) do
            if buf<curbuf then
                pos=table.remove(M.buf_get_cursors(buf))
                if pos then break end
            end
        end
    end
    if not pos then
        for _,buf in ipairs(vim.fn.reverse(vim.api.nvim_list_bufs())) do
            if buf>curbuf then
                pos=table.remove(M.buf_get_cursors(buf))
                if pos then break end
            end
        end
    end
    if not pos then
        pos=table.remove(vim.api.nvim_buf_get_extmarks(0,M.ns,0,-1,{}))
    end
    if not pos then return end
    if create_cursor then M.create_cursor() end
    vim.api.nvim_win_set_cursor(0,{pos[2]+1,pos[3]})
    M.del_cursor(pos[1])
end
function M.del_cursor(extmark_id)
    vim.api.nvim_buf_del_extmark(M.data[extmark_id].buf,M.ns,extmark_id)
    M.data[extmark_id]=nil
end
function M.clear_cursor(buf)
    for _,v in ipairs(vim.api.nvim_buf_get_extmarks(buf or 0,M.ns,0,-1,{})) do
        M.del_cursor(v[1])
    end
    vim.cmd.redraw{bang=true}
end
function M._update(buf,win)
    if vim.bo[buf].buftype~='' then return end
    local curwin=vim.api.nvim_get_current_win()
    local tns=vim.api.nvim_create_namespace'small_cursor_ephemeral'
    local cursors=vim.api.nvim_buf_get_extmarks(buf,M.ns,0,-1,{})
    if M.conf.show_cursors then
        for _,v in ipairs(vim.fn.win_findbuf(buf)) do
            if v~=curwin or curwin~=win then
                local row,col=unpack(vim.api.nvim_win_get_cursor(v))
                table.insert(cursors,{-1,row-1,col})
            end
        end
    end
    for _,v in ipairs(cursors) do
        if v[3]>=#vim.fn.getline(v[2]+1) then
            vim.api.nvim_buf_set_extmark(buf,tns,v[2],v[3],{
                virt_text={{' ','Cursor'}},
                virt_text_pos='overlay',
                ephemeral=true,
            })
        else
            vim.api.nvim_buf_set_extmark(buf,tns,v[2],v[3],{end_col=v[3]+1,hl_group='Cursor',ephemeral=true})
        end
    end
end
function M.setup()
    vim.api.nvim_set_decoration_provider(M.ns,{on_win=function (_,winid,bufnr,_)
        M._update(bufnr,winid)
    end})
    if M.conf.show_cursors then
        vim.api.nvim_create_autocmd('CursorMoved',{callback=function ()
            vim.cmd.redraw{bang=true}
        end})
    end
    vim.api.nvim_create_autocmd('BufDelete',{callback=function (ev)
        for _,v in ipairs(vim.api.nvim_buf_get_extmarks(ev.buf,M.ns,0,-1,{})) do
            M.del_cursor(v[1])
        end
    end})
end
if vim.dev then
    vim.api.nvim_buf_clear_namespace(0,M.ns,0,-1)
    vim.keymap.set('n','m',function() M.create_cursor() end)
    vim.keymap.set('n',"'",function() M.goto_next_cursor(true) end)
    vim.keymap.set('n',"<C-'>",function() M.goto_next_cursor() end)
    vim.keymap.set('n','<F1>',function() M.clear_cursor() end)
    M.setup()
end
return M
