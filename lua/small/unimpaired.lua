local M={}
function M.last(path,first)
    local parlist=vim.fn.readdir(vim.fs.dirname(path))
    return parlist[first and 1 or #parlist]==vim.fs.basename(path)
end
function M.dontbelast(path,first)
    for i in vim.fs.parents(vim.fs.joinpath(path,'.')) do
        if not M.last(i,first) then return i end
    end
    error()
end
function M.getnext(path,prev)
    if vim.fn.isdirectory(path)==1 and not vim.tbl_isempty(vim.fn.readdir(path)) then
        return vim.fs.joinpath(path,vim.fn.readdir(path)[prev and #vim.fn.readdir(path) or 1])
    end
    path=M.dontbelast(path,prev)
    local parent=vim.fs.dirname(path)
    local parlist=vim.fn.readdir(parent)
    return vim.fs.joinpath(parent,parlist[vim.fn.index(parlist,vim.fs.basename(path))+(prev and 0 or 2)])
end
function M.get_next_file(path,prev)
    path=vim.fn.fnamemodify(path,':p')
    path=M.getnext(path,prev)
    while vim.fn.isdirectory(path)==1 do path=M.getnext(path,prev) end
    return path
end
function M.toggle(opt,on,off)
    if off then vim.o[opt]=vim.o[opt]==on and off or on
    elseif on then vim.o[opt]=vim.o[opt]=='' and on or ''
    else
        if opt=='diff' then vim.cmd'setl invdiff'
        else vim.o[opt]=not vim.o[opt] end
    end
    print(opt..'='..vim.inspect(vim.o[opt]))
end
function M.set_opt()
    local opts={
        b={opt='background',on='light',off='dark'},c='cursorline',
        h='hlsearch',l='list',n='number',r='relativenumber',
        s='spell',u='cursorcolumn',w='wrap',d='diff',
        t={opt='colorcolumn',on='1,41,81,121,161,201,241'},
        v={opt='virtualedit',on='block,onemore'},M={opt='mouse',on='a'},
        f='foldenable',e='scrollbind',m={opt='conceallevel',on=2,off=0},
        T={opt='showtabline',on=1,off=0},L={opt='laststatus',on=2,off=0},
        C={opt='cmdheight',on=1,off=0},B={opt='showbreak',on='↳'},
    }
    local buf=vim.api.nvim_create_buf(false,true)
    vim.api.nvim_buf_set_option(buf,'bufhidden','wipe')
    for _,k in ipairs(vim.fn.reverse(vim.fn.sort(vim.tbl_keys(opts)))) do
        vim.api.nvim_buf_set_lines(buf,0,0,false,{k..' : '..(opts[k].opt or opts[k])})
    end
    local win=vim.api.nvim_open_win(buf,false,{
        relative='editor',width=vim.o.columns-20,height=vim.o.lines-20,col=10,row=10,
        focusable=false,style='minimal',noautocmd=true
    })
    vim.schedule(function ()
        local char=vim.fn.getcharstr()
        local v=opts[char]
        vim.api.nvim_win_close(win,true)
        if not v then return end
        M.toggle(v.opt or v,v.on,v.off)
    end)
end
function M.edit_next_file()
    vim.cmd.edit(M.get_next_file(vim.fn.expand('%')))
end
function M.edit_prev_file()
    vim.cmd.edit(M.get_next_file(vim.fn.expand('%'),true))
end
return M
