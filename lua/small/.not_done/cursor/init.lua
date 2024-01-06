local M={ns=vim.api.nvim_create_namespace'small_cursor',data={}}
function M.create_cursor()
    local row,col=unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_extmark(0,M.ns,row-1,col,{})
end
function M.jump_to_next_cursor(create_cursor)
    local row,col=unpack(vim.api.nvim_win_get_cursor(0))
    local pos=vim.api.nvim_buf_get_extmarks(0,M.ns,{row-1,col+1},-1,{})[1]
    if not pos then
        --TODO: if no cursor found after, try finding cursors in other buffers
        --PERF: create a cache which contains which buffers MAY contain cursor
        pos=vim.api.nvim_buf_get_extmarks(0,M.ns,0,-1,{})[1]
    end
    if not pos then return end
    if create_cursor then M.create_cursor() end
    vim.api.nvim_win_set_cursor(0,{pos[2]+1,pos[3]})
    M.del_cursor(0,pos[1])
end
function M.jump_to_prev_cursor(create_cursor)
    local row,col=unpack(vim.api.nvim_win_get_cursor(0))
    local pos=table.remove(vim.api.nvim_buf_get_extmarks(0,M.ns,0,{row-1,col-1},{}))
    if not pos then
        pos=table.remove(vim.api.nvim_buf_get_extmarks(0,M.ns,0,-1,{}))
    end
    if not pos then return end
    if create_cursor then M.create_cursor() end
    vim.api.nvim_win_set_cursor(0,{pos[2]+1,pos[3]})
    M.del_cursor(0,pos[1])
end
function M.del_cursor(buf,extmark_id)
    M.data=nil
    vim.api.nvim_buf_del_extmark(buf,M.ns,extmark_id)
end
function M.clear_cursor(buf)
    for _,v in ipairs(vim.api.nvim_buf_get_extmarks(buf or 0,M.ns,0,-1,{})) do
        M.del_cursor(buf or 0,v[1])
    end
end
function M._update(buf)
    local tns=vim.api.nvim_create_namespace'small_cursor_ephemeral'
    for _,v in ipairs(vim.api.nvim_buf_get_extmarks(buf,M.ns,0,-1,{})) do
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
if vim.dev then
    vim.api.nvim_buf_clear_namespace(0,M.ns,0,-1)
    vim.keymap.set('n','<F1>',function() M.create_cursor() end)
    vim.keymap.set('n','<F2>',function() M.jump_to_next_cursor() end)
    vim.keymap.set('n','<F3>',function() M.jump_to_prev_cursor() end)
    vim.api.nvim_set_decoration_provider(M.ns,{on_win=function (_,_,bufnr,_)
        M._update(bufnr)
    end})
end
return M
