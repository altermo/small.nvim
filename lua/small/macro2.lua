local M={}
function M.edit()
    local reg=vim.v.register=='"' and 'q' or vim.v.register
    local macro=vim.fn.input('>',vim.fn.keytrans(vim.fn.getreg(reg)))
    if vim.trim(macro)~='' then
        vim.fn.setreg((reg),vim.keycode(macro))
    end
end
function M.setup()
    M.au_group=vim.api.nvim_create_augroup('small.macro2',{})
    vim.api.nvim_create_autocmd('RecordingLeave',{callback=function ()
        if vim.v.event.regcontents=='' then
            vim.notify'empty macro, previous recoding is kept'
            vim.schedule_wrap(function (prev)
                vim.fn.setreg('q',prev)
            end)(vim.fn.getreg'q')
            return
        end
        vim.notify('Recorded macro: '..vim.fn.keytrans(assert(vim.v.event.regcontents)))
    end,group=M.au_group})
    vim.api.nvim_create_autocmd('RecordingEnter',{callback=function ()
        vim.notify'Recording macro'
    end})
    vim.keymap.set('n','q','reg_recording()==""?"qq":"q"',{expr=true,noremap=true})
    vim.keymap.set('n','q',function ()
        if vim.fn.reg_recording()~='' then
            return 'q'
        elseif vim.v.register~='"' then
            return 'q'..vim.v.register
        else
            return 'qq'
        end
    end,{expr=true,noremap=true})
    vim.keymap.set('n','Q',function ()
        if vim.fn.reg_recording()~='' then
            vim.notify("Cant play macro while recoding")
        elseif vim.fn.reg_executing()~='' then
        elseif vim.v.register~='"' then
            return '@'..vim.v.register
        else
            return '@q'
        end
    end,{expr=true,noremap=true})
end
return M
