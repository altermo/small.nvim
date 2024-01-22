local M={}
function M.update()
    local cur=vim.api.nvim_win_get_cursor(0)
    local row,col=cur[1]-1,cur[2]
    local win=vim.api.nvim_get_current_win()
    local winopt=vim.api.nvim_win_get_config(win)
    local zindex=winopt.zindex or 0
    for _,v in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local opt=vim.api.nvim_win_get_config(v)
        if (opt.zindex or 0)<=zindex then
            goto continue
        end
        vim.pprint(opt)
        ::continue::
    end
end
function M.setup()
    M.update()
end
if vim.dev then
    local function f(text)
        local buf=vim.api.nvim_create_buf(false,true)
        vim.bo[buf].bufhidden='wipe'
        vim.api.nvim_buf_set_lines(buf,0,-1,false,{text})
        return buf
    end
    vim.api.nvim_open_win(f'1',true,{
        relative='editor',
        col=1,
        row=1,
        width=20,
        height=10,
        zindex=100,
    })
    vim.api.nvim_open_win(f'2',true,{
        relative='editor',
        col=5,
        row=5,
        width=20,
        height=10,
    })
    M.setup()
end
return M
