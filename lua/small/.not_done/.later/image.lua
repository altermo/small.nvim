local lpeg=vim.lpeg
local P,V,R,S=vim.lpeg.P,lpeg.V,lpeg.R,lpeg.S
local C,Ct,Cc=vim.lpeg.C,lpeg.Ct,lpeg.Cc

local M={}

M.ns=vim.api.nvim_create_namespace'small_image'

M.start_id='\x1b]-1;G'

M.pattern=P({
    V'OSC'*V'action'^1*P'&',
    OSC=P(M.start_id),
    action=P'!'*Ct(V'create'),
    create=((Cc'cmd'*C(P('c')))%rawset)*P';'*
        ((Cc'file'*V'file_path')%rawset)*
        (((V'position_attr'+V'id_attr')*';')%rawset)^0,
    file_path=C((P(1)-P'//')^1)*'//',
    position_attr=C(S'hwrc')*'='*C(V'number'),
    id_attr=C(S'i')*'='*C(V'name'),
    number=R'19'^1,
    name=(R'19'+R'az'+R'AZ')^1,
})

vim.api.nvim_create_autocmd('TermRequest',{
    group=vim.api.nvim_create_augroup('test',{}),
    callback=function (ev)
        local buf=ev.buf
        local request=vim.v.termrequest
        if request:sub(1,#M.start_id)~=M.start_id then return end
        ---@type table<string,string>[]
        local actions={M.pattern:match(vim.v.termrequest)}
        if vim.tbl_isempty(actions) then
            vim.notify('Received a bad graphics request: '..vim.inspect(request))
        end
        for _,v in ipairs(actions) do
            if v.cmd=='c' then
                vim.schedule(function ()
                    vim.api.nvim_buf_set_extmark(buf,M.ns,0,0,{
                        hl_group='Comment',
                        end_col=1,
                        strict=false,
                    })
                end)
            end
        end
    end
})
if vim.dev then
    pcall(vim.api.nvim_buf_delete,buf,{force=true})
    local buf=vim.api.nvim_create_buf(false,true)
    _G.buf=buf
    vim.bo[buf].bufhidden='wipe'
    local chan=vim.api.nvim_open_term(buf,{})
    vim.api.nvim_open_win(buf,false,{split='right'})
    vim.fn.chansend(chan,"foo\naaa")
    vim.fn.chansend(chan,"\x1b]G!c;/home/user/Downloads/a.png//r=1;c=1;&")
end

return M
