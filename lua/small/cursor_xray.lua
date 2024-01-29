local M={}
function M.update()
    local winopt=vim.api.nvim_win_get_config(0)
    local winpos=vim.api.nvim_win_get_position(0)
    local currow=vim.fn.winline()
    local curcol=vim.fn.wincol()
    local row=currow+winpos[1]
    local col=curcol+winpos[2]
    local zindex=winopt.zindex or 0
    local maxzindex=nil
    if M.win then
        vim.api.nvim_win_close(M.win,true)
        M.win=nil
    end
    for _,v in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local opt=vim.api.nvim_win_get_config(v)
        if (opt.zindex or 0)<=zindex then
            goto continue
        end
        local winrow=opt.row[false]
        local wincol=opt.col[false]
        if row<winrow+1 or row>winrow+opt.height or col<wincol+1 or col>wincol+opt.width then
            goto continue
        end
        maxzindex=math.max(opt.zindex,maxzindex or -1)
        ::continue::
    end
    if not maxzindex then return end
    local nwinrow=-1
    local nwincol=-1
    local nwinheight=3
    local nwinwidth=3
    if currow==1 then
        nwinrow=0
        nwinheight=nwinheight-1
    end
    if currow==vim.fn.winheight(0) then
        nwinheight=nwinheight-1
    end
    if curcol==1 then
        nwincol=0
        nwinwidth=nwinwidth-1
    end
    if curcol==vim.fn.winwidth(0) then
        nwinwidth=nwinwidth-1
    end
    local view=vim.fn.winsaveview()
    view.topline=currow-1
    view.leftcol=curcol-2
    M.win=vim.api.nvim_open_win(0,false,{
        style='minimal',
        relative='editor',
        width=nwinwidth,
        height=nwinheight,
        row=nwinrow+row-1,
        col=nwincol+col-1,
        zindex=maxzindex+1,
        focusable=false,
    })
    vim.wo[M.win].wrap=false
    vim.api.nvim_win_call(M.win,function()
        vim.fn.winrestview(view)
    end)
end
function M.setup()
    vim.api.nvim_create_autocmd({'CursorMoved','CursorMovedI'},{callback=M.update,group=vim.api.nvim_create_augroup('small_cursorxray',{})})
end
if vim.dev then
    local function f(text)
        local buf=vim.api.nvim_create_buf(false,true)
        vim.bo[buf].bufhidden='wipe'
        vim.api.nvim_buf_set_lines(buf,0,-1,false,{text})
        return buf
    end
    vim.api.nvim_open_win(f'2',true,{
        relative='editor',
        col=1,
        row=1,
        width=20,
        height=10,
    })
    M.setup()
end
return M
