local M={conf={options={
    r={desc='ranger',action=function() require'small.ranger'.run() end},
    f={desc='shell',action=vim.fn.termopen},
    s={
        desc='scratch',
        action=function ()
            local buf=vim.api.nvim_create_buf(true,true)
            vim.api.nvim_set_option_value('bufhidden','wipe',{buf=buf})
            vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(),buf)
        end
    }
}}}
function M.open()
    local buf=vim.api.nvim_create_buf(false,true)
    vim.api.nvim_set_option_value('bufhidden','wipe',{buf=buf})
    local win=vim.api.nvim_open_win(buf,false,{
        relative='win',width=math.max(vim.fn.winwidth(0)-50,20),height=math.max(vim.fn.winheight(0)-10,10),col=30,row=5,
        focusable=false,style='minimal',noautocmd=true})
    vim.wo[win].winblend=50
    for k,v in pairs(M.conf.options) do
        vim.api.nvim_buf_set_lines(buf,0,0,false,{k..' : '..v.desc})
    end
    vim.cmd.redraw()
    local char=vim.fn.getcharstr()
    vim.api.nvim_win_close(win,true)
    if M.conf.options[char] then M.conf.options[char].action()
    else vim.api.nvim_feedkeys(char,'m',true) end
end
function M.vsplit() vim.cmd.vsplit() M.open() end
function M.split() vim.cmd.split() M.open() end
return M
