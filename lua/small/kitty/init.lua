local M={conf={}}
function M.in_kitty()
    if M.conf.strict then
        if not vim.env.TERM:find('kitty') or vim.env.NVIM then return end
        local proc=vim.api.nvim_get_proc(vim.fn.getpid())
        local function parent() proc=vim.api.nvim_get_proc(proc.ppid) end
        repeat parent() until proc.name~='nvim'
        return proc.name=='kitty'
    end
    return vim.env.TERM:find('kitty') and not vim.env.NVIM
end
function M.send_cmd(...)
    vim.system(vim.list_extend({'kitty','@'},{...}))
end
function M.get_kitty_winid(cb)
    local f=vim.schedule_wrap(cb)
    vim.system({'kitty','@','ls'},{timeout=1000},function (info)
        local s,json=pcall(vim.json.decode,info.stdout)
        if not s then
            vim.notify('kitty window id not found',vim.log.levels.WARN)
            return
        end
        f(json[1].platform_window_id)
    end)
end
function M.sync_background()
    M.send_cmd('set-color','background=#'..vim.fn.printf('%06x',vim.api.nvim_get_hl(0,{name='Normal'}).bg))
end
function M.sync_font_size()
    M.send_cmd('set-font-size',M.get_font_size())
end
function M.setup()
    if not M.in_kitty() then return end
    if not  M.conf.no_sync_bg then
        vim.api.nvim_create_autocmd('ColorScheme',{callback=M.sync_background})
        M.sync_background()
        vim.defer_fn(M.sync_background,100)
    end
    vim.api.nvim_create_autocmd('OptionSet',{pattern='guifont',callback=M.sync_font_size})
    M.sync_font_size()
    if not M.conf.no_keymap then M.setup_keymaps() end
    if M.conf.padding then M.set_padding(M.conf.padding) end
    if M.conf.original_padding then
        vim.api.nvim_create_autocmd('VimLeave',{callback=function ()
            M.set_padding(M.conf.original_padding)
        end})
    end
end
function M.set_font_size(size) vim.o.guifont=vim.o.guifont:gsub(':h%d*',':h'..size) end
function M.get_font_size() return vim.o.guifont:match(':h(%d*)') end
function M.setup_keymaps()
    local default_font=M.get_font_size()
    vim.keymap.set({'t','n'},'<C-0>',function () M.set_font_size(default_font) end)
    vim.keymap.set({'t','n'},'<C-+>',function () M.set_font_size(M.get_font_size()+1) end)
    vim.keymap.set({'t','n'},'<C-S-=>',function () M.set_font_size(M.get_font_size()+1) end)
    vim.keymap.set({'t','n'},'<C-->',function ()
        local font_size=tonumber(M.get_font_size())
        M.set_font_size(font_size>1 and font_size-1 or 1)
    end)
end
function M.set_padding(size)
    M.padding=size
    M.send_cmd('set-spacing','padding='..size)
end
function M.toggle_padding(size)
    if M.padding==size then M.set_padding(3)
    else M.set_padding(size) end
end
return M
