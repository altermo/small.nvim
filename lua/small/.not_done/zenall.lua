local M={buf=vim.api.nvim_create_buf(false,true)}
function M.set_win(win)
    vim.wo[win].number=false
    vim.wo[win].relativenumber=false
    vim.wo[win].cursorline=false
    vim.wo[win].colorcolumn=''
    vim.wo[win].signcolumn='no'
end
function M.make_right_win(s)
    vim.cmd'rightbelow vsplit'
    vim.api.nvim_set_current_buf(M.buf)
    s.right=vim.api.nvim_get_current_win()
    M.set_win(s.right)
    vim.cmd.wincmd'p'
end
function M.make_left_win(s)
    vim.cmd'leftabove vsplit'
    vim.api.nvim_set_current_buf(M.buf)
    s.left=vim.api.nvim_get_current_win()
    M.set_win(s.left)
    vim.cmd.wincmd'p'
end
function M.make_win_zen(s)
    local saveopt=vim.o.equalalways
    local savewin=vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(s.win)
    vim.o.equalalways=false
    M.make_left_win(s)
    M.make_right_win(s)
    M.savef[s.left]=s
    M.savef[s.right]=s
    vim.api.nvim_set_current_win(savewin)
    vim.o.equalalways=saveopt
end
function M.resize_all()
    local s=vim.tbl_keys(M.save)
    table.sort(s,function(a,b) return vim.api.nvim_win_get_position(a)[2]<vim.api.nvim_win_get_position(b)[2] end)
    for _,v in ipairs(s) do
        local m=M.save[v]
        vim.api.nvim_win_set_width(m.left,math.floor((m.width-math.floor(m.width/10*8))/2))
        vim.api.nvim_win_set_width(m.win,math.floor(m.width/10*8))
        vim.api.nvim_win_set_width(m.right,m.width-math.floor((m.width-math.floor(m.width/10*8))/2)-math.floor(m.width/10*8))
    end
end
function M.run()
    M.save={}
    M.savef={}
    for _,win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        vim.api.nvim_set_current_win(win)
        local width=vim.api.nvim_win_get_width(win)
        local s={win=win,width=width}
        M.save[win]=s
    end
    for _,v in pairs(M.save) do
        M.make_win_zen(v)
    end
    M.resize_all()
    M.set_autocmds()
end
function M.derun()
    if not M.save then return end
    for _,v in pairs(M.save) do
        vim.api.nvim_win_close(v.left,true)
        vim.api.nvim_win_close(v.right,true)
        vim.api.nvim_win_set_width(v.win,v.width)
    end
    M.save=nil
end
function M.set_autocmds()
    local g=vim.api.nvim_create_augroup('ZenAll',{})
    vim.api.nvim_create_autocmd('WinEnter',{callback=function () end,group=g})
    vim.api.nvim_create_autocmd('WinClosed',{callback=function () end,group=g})
    vim.api.nvim_create_autocmd('WinResized',{callback=function () end,group=g})
end
if vim.dev then
    M.run()
    --M.derun()
end
return M
