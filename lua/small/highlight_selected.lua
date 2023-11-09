local M={}
M.prev_match=nil
function M.get_visual()
    local reg=vim.region(0,'v','.','',true)
    if vim.tbl_count(reg)>1 then return end
    local linenr,pos=next(reg)
    local start,fin=unpack(pos)
    if not linenr then return end
    return vim.api.nvim_buf_get_lines(0,linenr,linenr+1,false)[1]:sub(start+1,fin)
end
function M.clear()
    if not M.prev_match then return end
    pcall(vim.fn.matchdelete,unpack(M.prev_match))
    M.prev_match=nil
end
function M.do_highlight()
    M.clear()
    local line=M.get_visual()
    if not line or vim.trim(line)=='' or #line<2 then return end
    if vim.fn.type(line)==10 then return end
    M.prev_match={vim.fn.matchadd('Visual','\\M'..vim.fn.escape(line,'\\')),vim.api.nvim_get_current_win()}
end
function M.setup()
    vim.api.nvim_create_augroup('hisel',{})
    local id
    vim.api.nvim_create_autocmd('ModeChanged',{group='hisel',callback=function ()
        M.do_highlight()
        id=vim.api.nvim_create_autocmd('CursorMoved',{callback=M.do_highlight})
    end,pattern='*:[v\x16]'})
    vim.api.nvim_create_autocmd('ModeChanged',{group='hisel',callback=function ()
        if id then vim.api.nvim_del_autocmd(id) id=nil end
        M.clear()
    end,pattern='[v\x16]:*'})
end
return M
