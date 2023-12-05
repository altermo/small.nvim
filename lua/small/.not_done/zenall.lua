local M={
    ns=vim.api.nvim_create_namespace'small_zenall',
    augroup=vim.api.nvim_create_augroup('small_zenall',{}),
}
function M.redraw(buf)
    _=buf
end
function M.wininit(win)
    if not vim.b[vim.api.nvim_win_get_buf(win)].small_zenall_enabled then return end
    if vim.w[win].small_zenall_enabled then return end
    local save={}
    for k,v in pairs({
        showbreak='',
        wrap=false,
        cursorline=false,
        signcolumn='no',
        statuscolumn='',
    }) do
        save[k]=vim.wo[win][k]
        vim.wo[win][k]=v
    end
    vim.w[win].small_zenall_enabled=save
end
function M.windeinit(win)
    if vim.b[vim.api.nvim_win_get_buf(win)].small_zenall_enabled then return end
    if not vim.w[win].small_zenall_enabled then return end
    for k,v in pairs(vim.w[win].small_zenall_enabled) do
        vim.wo[win][k]=v
    end
    vim.w[win].small_zenall_enabled=nil
end
function M.setup()
    if M.hassetup then return end
    M.hassetup=true
    local function redraw(ev)
        M.redraw(ev.buf)
        vim.schedule_wrap(M.redraw)(ev.buf)
    end
    local function wininit() M.wininit(vim.api.nvim_get_current_win()) end
    local function windeinit() M.windeinit(vim.api.nvim_get_current_win()) end
    vim.api.nvim_create_autocmd({
        'CursorMoved',
        'CursorMovedI',
        'TextChanged',
        'TextChangedI',
        'TextChangedP',
        'WinResized',
    },{callback=redraw,group=M.augroup})
    vim.api.nvim_create_autocmd({
        'BufWinEnter',
        'WinEnter',
    },{callback=wininit,group=M.augroup})
    vim.api.nvim_create_autocmd({
        'BufWinLeave',
        'BufLeave',
        'BufEnter'
    },{callback=windeinit,group=M.augroup})
end
function M.run(buf)
    if vim.b[buf].small_zenall_enabled then return end
    vim.b[buf].small_zenall_enabled=true
    M.setup()
    M.redraw(buf)
    M.wininit(vim.api.nvim_get_current_win())
end
if vim.dev then
    vim.b[vim.api.nvim_get_current_buf()].small_zenall_enabled=false
    vim.api.nvim_del_augroup_by_id(M.augroup)
    M.augroup=vim.api.nvim_create_augroup('small_zenall',{})
    M.hassetup=false
    M.run(0)
end
