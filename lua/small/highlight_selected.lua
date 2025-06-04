local M={}
M.prev_match_win=nil
function M.get_visual()
    if not vim.fn.mode():find'[vV\x16]' then
        return
    end
    local text=vim.fn.getregion(vim.fn.getpos'v',vim.fn.getpos'.',{type=vim.fn.mode()})
    if vim.fn.mode()=='\x16' and #text>1 then return end
    return table.concat(text,'\n')
end
function M.clear()
    if not M.prev_match_win then return end
    for k,v in pairs(M.prev_match_win) do
        pcall(vim.fn.matchdelete,v,k)
    end
    M.prev_match_win=nil
end
function M.do_highlight()
    M.clear()
    local text=M.get_visual()
    if not text or vim.trim(text)=='' or #text<2 then return end
    if vim.fn.type(text)==10 then return end
    M.prev_match_win={}
    for _,win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        vim._with({emsg_silent=true,silent=true},function ()
            local id=vim.fn.matchadd('Visual','\\M'..text:gsub('\\','\\\\'):gsub('\n','\\n'),100,-1,{window=win})
            M.prev_match_win[win]=id
        end)
    end
end
function M.setup()
    vim.api.nvim_create_augroup('hisel',{})
    local id
    vim.api.nvim_create_autocmd('ModeChanged',{group='hisel',callback=function ()
        M.do_highlight()
        id=vim.api.nvim_create_autocmd('CursorMoved',{callback=M.do_highlight})
    end,pattern='*:[vV\x16]'})
    vim.api.nvim_create_autocmd('ModeChanged',{group='hisel',callback=function ()
        if id then vim.api.nvim_del_autocmd(id) id=nil end
        M.clear()
    end,pattern='[vV\x16]:*'})
end
return M
