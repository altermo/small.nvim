local M={}
function M.toggle_rec()
    if vim.fn.reg_recording()=='' then
        vim.cmd.normal{'qq',bang=true}
        vim.notify('started recording',vim.log.levels.INFO)
        return
    end
    local prev=vim.fn.getreg('q')
    vim.cmd.normal{'q',bang=true}
    local new=vim.fn.getreg('q') --[[@as string]]
    if new=='q' then
        vim.notify('empty macro, previous recoding is kept',vim.log.levels.INFO)
        vim.fn.setreg('q',prev)
        return
    end
    vim.fn.setreg('q',new:sub(1,-2))
    vim.notify('Recorded macro: '..vim.fn.keytrans(new:sub(1,-2)),vim.log.levels.INFO)
end
function M.play_rec()
    if vim.fn.reg_recording()~='' then
        vim.notify('Cant play macro while recoding, stoping recording',vim.log.levels.ERROR)
        local prev=vim.fn.getreg('q')
        vim.cmd.normal{'q',bang=true}
        vim.fn.setreg('q',prev)
        return
    end
    vim.cmd.normal{vim.v.count1..'@q',bang=true}
end
function M.edit_rec()
    local reg=vim.fn.getreg('q') --[[@as string]]
    vim.ui.input({
        prompt='>',
        default=vim.fn.keytrans(reg),
    },function (inp)
            if not inp or vim.trim(inp)=='' then return end
            vim.fn.setreg('q',vim.keycode(inp))
        end)
end
return M
