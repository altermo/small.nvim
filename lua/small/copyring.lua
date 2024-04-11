local M={augroup=vim.api.nvim_create_augroup('small_copy',{clear=true})}
function M.highlight(event)
    vim.highlight.on_yank{higroup='Search',timeout=500,event=event}
end
M.copies={{cont=vim.split(vim.fn.getreg'"','\n'),type=vim.fn.getregtype'"'}}
function M.create_cancel(first)
    if not M.state then return end
    if not first then
        vim.api.nvim_del_autocmd(M.state.au)
    end
    vim.schedule(function ()
        if not M.state then return end
        M.state.au=vim.api.nvim_create_autocmd('CursorMoved',{callback=function ()
            M.state=nil
        end,once=true})
    end)
end
function M.cycle(forward)
    if not M.state then
        return
    end
    if forward then
        M.state.idx=M.state.idx-1
        if M.state.idx<1 then
            M.state.idx=1
            return
        end
    else
        M.state.idx=M.state.idx+1
        if M.state.idx>#M.copies then
            M.state.idx=#M.copies
            return
        end
    end
    local st=M.copies[M.state.idx]
    local r=vim.fn.getreg('x',true)
    local rt=vim.fn.getregtype('x')
    vim.fn.setreg('x',st.cont,st.type)
    M.create_cancel()
    vim.cmd(('norm! u%s"x%s'):format(M.state.count,M.state.after and 'p' or 'P'))
    M.highlight{operator='y',inclusive=true,regtype=st.type}
    vim.fn.setreg('x',r,rt)
end
function M.put(after)
    local regtype=vim.fn.getregtype(vim.v.register)
    vim.cmd(('norm! %s"%s%s'):format(vim.v.count1,vim.v.register,after and 'p' or 'P'))
    M.highlight{operator='y',inclusive=true,regtype=regtype}
    if vim.v.register=='"' then
        M.state={
            count=vim.v.count1,
            idx=1,
            after=after,
        }
        M.create_cancel(true)
    end
end
function M.push(regcont,regtype)
    if table.concat(M.copies[1].cont,'\n')==table.concat(regcont,'\n') and M.copies[1].type==regtype then
        return
    end
    table.insert(M.copies,1,{cont=regcont,type=regtype})
    if #M.copies>10 then
        table.remove(M.copies)
    end
end
function M.setup()
    vim.api.nvim_create_autocmd('TextYankPost',{callback=function ()
        M.highlight()
        if vim.v.register=='"' then
            M.push(vim.v.event.regcontents,vim.v.event.regtype)
        end
    end,group=M.augroup})
    vim.keymap.set('n','p',function () M.put(true) end)
    vim.keymap.set('n','P',function () M.put(false) end)
    vim.keymap.set('n','<A-p>',function () M.cycle(false) end)
    vim.keymap.set('n','<A-P>',function () M.cycle(true) end)
end
if vim.dev then
    M.setup()
end
return M
