local M={}
M.save={opt={}}
function M.set_win()
    vim.wo.number=false
    vim.wo.relativenumber=false
    vim.wo.cursorline=false
    vim.wo.colorcolumn=''
    vim.wo.signcolumn='no'
end
function M.run()
    if vim.t.zen_mode then
        vim.api.nvim_del_autocmd(M.save.au)
        vim.cmd.tabclose()
        for k,v in pairs(M.save.opt) do vim.o[k]=v end
        M.save={opt={}}
        local s,t=pcall(require,'twilight') if s then t.disable() end
        _G.CMD_NO_SPAM=false
        return
    end
    vim.cmd'-1 tab split'
    M.set_win()
    vim.cmd'rightbelow vnew'
    M.save.right=vim.api.nvim_get_current_win()
    M.set_win() vim.cmd.wincmd'p'
    vim.cmd'leftabove vnew'
    M.save.left=vim.api.nvim_get_current_win()
    M.set_win() vim.cmd.wincmd'p'
    vim.t.zen_mode=true
    vim.api.nvim_create_autocmd('WinLeave',{callback=M.run,once=true})
    for k,v in pairs({laststatus=0,showtabline=0,cmdheight=0}) do
        M.save.opt[k]=vim.o[k]
        vim.o[k]=v
    end
    M.win_resize()
    M.save.au=vim.api.nvim_create_autocmd('WinResized',{callback=M.win_resize})
    local s,t=pcall(require,'twilight') if s then t.enable() end
    _G.CMD_NO_SPAM=true
end
function M.win_resize()
    vim.api.nvim_win_set_width(M.save.left,vim.fn.floor(vim.o.columns/5))
    vim.api.nvim_win_set_width(M.save.right,vim.fn.floor(vim.o.columns/5))
end
return M
