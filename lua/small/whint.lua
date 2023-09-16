local M={}
function M.getline(linenr)
    return vim.api.nvim_buf_get_lines(0,linenr-1,linenr,false)[1]
end
function M.in_lua()
    local stat,parser=pcall(vim.treesitter.get_parser,0)
    if not stat then return vim.o.filetype=='lua' end
    local pos=vim.api.nvim_win_get_cursor(0)
    return parser:language_for_range({pos[1]-1,pos[2],pos[1]-1,pos[2]}):lang()=='lua'
end
function M.should_statment()
    local pos=vim.api.nvim_win_get_cursor(0)
    local node=vim.treesitter.get_node({pos={pos[1]-1,pos[2]-1}})
    if not node or node:type()~='identifier' then return end
    local par=node:parent()
    return par and par:type()=='parameters'
end
function M.get_name()
    local pos=vim.api.nvim_win_get_cursor(0)
    local node=vim.treesitter.get_node({pos={pos[1]-1,pos[2]-1}})
    if not node then return end
    local _,start,_,end_=node:range()
    return vim.api.nvim_get_current_line():sub(start+1,end_)
end
function M.has_return(linenr)
    return linenr>1 and M.getline(linenr-1):find('---@return ')
end
function M.get_pos(name,linenr)
    while M.getline(linenr-1) and M.getline(linenr-1):find('---@param') do
        linenr=linenr-1
        local _,_,var,_=M.getline(linenr):find('---@param ([^ ]*) (.*)')
        if var==name then return linenr,11+#name end
    end
end
function M.run_statment()
    local linenr,col=unpack(vim.api.nvim_win_get_cursor(0))
    local off=M.has_return(linenr) and 1 or 0
    local name=M.get_name()
    local pos,pcol=M.get_pos(name,linenr-off)
    if not pos then
        vim.api.nvim_buf_set_lines(0,linenr-off-1,linenr-off-1,true,{'---@param '..name..' '})
        pos=linenr-off
        pcol=#name+11
        linenr=linenr+1
    end
    vim.api.nvim_win_set_cursor(0,{pos,pcol})
    M.create_return_autocmd(linenr,col)
end
function M.should_return()
    local pos=vim.api.nvim_win_get_cursor(0)
    local node=vim.treesitter.get_node({pos={pos[1]-1,pos[2]-1}})
    if not node then return end
    return node:type()=='parameters'
end
function M.run_return()
    local linenr,col=unpack(vim.api.nvim_win_get_cursor(0))
    if not M.has_return(linenr) then
        vim.api.nvim_buf_set_lines(0,linenr-1,linenr-1,true,{'---@return '})
        linenr=linenr+1
    end
    vim.api.nvim_win_set_cursor(0,{linenr-1,11})
    M.create_return_autocmd(linenr,col)
end
function M.create_return_autocmd(linenr,col)
    local row=vim.fn.line('.')
    local mau
    local au=vim.api.nvim_create_autocmd('InsertCharPre',{callback=function(ev)
        if vim.v.char~='-' then return end
        vim.api.nvim_del_autocmd(ev.id)
        vim.api.nvim_del_autocmd(mau)
        vim.api.nvim_win_set_cursor(0,{linenr,col})
        vim.v.char=''
    end})
    mau=vim.api.nvim_create_autocmd({'CursorMoved','CursorMovedI'},{callback=function(ev)
        if vim.fn.line('.')==row then return end
        vim.api.nvim_del_autocmd(ev.id)
        vim.api.nvim_del_autocmd(au)
    end})
end
function M.run(key)
    if not M.in_lua() then return key end
    if M.should_statment() then vim.schedule(M.run_statment)
    elseif M.should_return() then vim.schedule(M.run_return)
    else return key end
end
function M.run_wrapp(key)
    return function ()
        return M.run(key)
    end
end
return M
