local M={ns=vim.api.nvim_create_namespace('small-bottombar')}
function M.render()
    pcall(vim.api.nvim_buf_delete,M.buf,{force=true})
    if vim.o.buftype~='' then
        return
    end
    M.buf=vim.api.nvim_create_buf(false,true)
    vim.bo[M.buf].bufhidden='wipe'
    local status='%l,%c%V %t'
    local lines={
        ---@diagnostic disable-next-line: undefined-field
        vim.api.nvim_eval_statusline(status,{}).str,
    }
    local s={}
    for _,v in ipairs(vim.diagnostic.get(0)) do
        s[v.severity]=(s[v.severity] or 0)+1
    end
    for i,v in vim.spairs(s) do
        i=({ERROR='󰅚 ',WARN='󰀪 ',INFO='󰋽 ',HINT='󰌶 '})[vim.diagnostic.severity[i]]
        table.insert(lines,1,i..v)
    end
    vim.api.nvim_buf_set_lines(M.buf,0,-1,false,lines)
    local basewin=vim.api.nvim_open_win(M.buf,false,{ relative = 'editor', hide = false, col = 0x7fffffff, row = 0x7fffffff, width = 1, height = 1, focusable = false, style = 'minimal', noautocmd = true,  })
    for k in ipairs(lines) do
        local win=vim.api.nvim_open_win(M.buf,false,{
            relative='win',
            win=basewin,
            width=vim.api.nvim_strwidth(lines[#lines-k+1]),
            height=1,
            row=-k+1,
            col=1,
            focusable=false,
            style='minimal',
            noautocmd=true,
            zindex=51,
        })
        vim.wo[win].winhighlight='Normal:Normal'
        vim.wo[win].winblend=100
        vim.api.nvim_win_set_cursor(win,{-k+#lines+1,0})
    end
end
function M.setup()
    vim.api.nvim_create_autocmd({'CursorMoved','CursorMovedI','DiagnosticChanged'},{
        callback=function()
            pcall(M.render)
        end,
        group=vim.api.nvim_create_augroup('small-bottombar',{}),
    })
    vim.api.nvim_create_autocmd({'OptionSet'},{
        callback=function()
            pcall(M.render)
        end,
        pattern='buftype',
        group=vim.api.nvim_create_augroup('small-bottombar',{clear=false}),
    })
    M.render()
end
return M