local M={ns=vim.api.nvim_create_namespace('small.colorfn')}
local actions={
    {j=2,k=0,h=function () M.state.r=math.max(M.state.r-1,0) end,l=function () M.state.r=M.state.r+1 end},
    {},
    {j=2,k=-2,h=function () M.state.g=math.max(M.state.g-1,0) end,l=function () M.state.g=M.state.g+1 end},
    {},
    {j=0,k=-2,h=function () M.state.b=math.max(M.state.b-1,0) end,l=function () M.state.b=M.state.b+1 end},
}
local function redraw(buf)
    for k,v in pairs(actions[M.state.line]) do
        vim.keymap.set('n',k,function ()
            if type(v)=='number' then
                M.state.line=M.state.line+v
            else
                v()
            end
            redraw(buf)
        end,{buffer=buf})
    end
    vim.api.nvim_buf_set_lines(buf,0,-1,false,{
        'R ',
        '',
        'G ',
        '',
        'B ',
    })
    vim.api.nvim_buf_clear_namespace(buf,M.ns,0,-1)
    local function t(n)
        return math.min(math.max(math.floor(n),0),255)
    end
    local function f(x)
        local b=bit.band(x,0xff)
        local g=bit.rshift(bit.band(x,0xff00),8)
        local r=bit.rshift(bit.band(x,0xff0000),16)
        r=r*M.state.r/10
        g=g*M.state.g/10
        b=b*M.state.b/10
        return t(b)+bit.lshift(t(g),8)+bit.lshift(t(r),16)
    end
    local bg=M.state.hl.Normal.bg
    local function c(nt,l)
        local n=M.state[nt]
        local min=math.max(0,n-8)
        local text={}
        for i=min,min+16 do
            M.state[nt]=i
            vim.api.nvim_set_hl(M.ns,'SmallColorfn'..nt..i,{bg=f(bg)})
            M.state[nt]=n
            vim.lg('SmallColorfn'..n..i)
            local ch=' '
            if i==10 then ch='_' end
            if i==n then ch='|' end
            if i==n and i==10 then ch='I' end
            table.insert(text,{ch,'SmallColorfn'..nt..i})
        end
        vim.api.nvim_buf_set_extmark(buf,M.ns,l,2,{
            virt_text=text,
        })
    end
    c('r',0)
    c('g',2)
    c('b',4)
    vim.api.nvim_win_set_cursor(M.win,{M.state.line,0})
    for name,attr in pairs(M.state.hl) do
        if attr.bg then
            attr=vim.deepcopy(attr)
            attr.bg=f(attr.bg)
            vim.api.nvim_set_hl(0, name, attr)
        end
    end
    vim.cmd.doautocmd('ColorScheme')
end
local function close()
    vim.api.nvim_win_close(M.win,true)
    M.win=nil
end
function M.run()
    if M.win then close() end
    M.state={r=10,g=10,b=10,line=1}
    M.state.hl=vim.api.nvim_get_hl(0,{})
    local buf=vim.api.nvim_create_buf(false,true)
    vim.bo[buf].bufhidden='wipe'
    local height=5
    M.win=vim.api.nvim_open_win(buf,true,{
        relative='editor',
        width=20,
        height=height,
        row=vim.o.lines-height,
        col=vim.o.columns-20,
        style='minimal',
        border='single',
        noautocmd=true,
    })
    vim.api.nvim_win_set_hl_ns(M.win,M.ns)
    vim.api.nvim_set_hl(M.ns,'NormalFloat',M.state.hl.Normal)
    vim.keymap.set('n','q',function ()
        close()
    end,{buffer=buf})
    redraw(buf)
end
return M
