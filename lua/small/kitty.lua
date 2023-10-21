local M={}
function M.in_kitty()
    return vim.o.term:find('kitty')
end
function M.send_cmd(...)
    vim.system(vim.list_extend({'kitty','@'},{...}))
end
function M.get_kitty_winid(cb)
    local f=vim.schedule_wrap(cb)
    vim.system({'kitty','@','ls'},{timeout=1000},function (info)
        local s,json=pcall(vim.json.decode,info.stdout)
        if not s then f() return end
        f(json[1].platform_window_id)
    end)
end
function M.setup()
    if not M.in_kitty() then return end
    vim.api.nvim_create_autocmd('ColorScheme',{callback=function()
        M.send_cmd('set-color','background=#'..vim.fn.printf('%06x',vim.api.nvim_get_hl(0,{name='Normal'}).bg))
    end})
    M.get_kitty_winid(function (kitty_winid)
        if not kitty_winid then vim.notify('kitty window id not found',vim.log.levels.WARN) end
        vim.system{'xprop','-f','_NET_WM_WINDOW_OPACITY','32c','-set','_NET_WM_WINDOW_OPACITY',
            vim.fn.printf('0x%08x',vim.fn.floor(0xFFFFFFFF*90/100)),
            '-id',kitty_winid}
    end)
    M.send_cmd('set-font-size','12')
end
return M
