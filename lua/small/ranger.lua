local M={conf={exit_if_single=false}}
function M.ranger(path)
    local realpath=vim.fn.fnamemodify(path,':p')
    local file='/tmp/chosenfile'
    local cmd=';ranger --cmd "map r chain cd ..;open_with" --choosefiles='..file
    vim.cmd.enew()
    local buf=vim.api.nvim_get_current_buf()
    vim.api.nvim_set_option_value('bufhidden','wipe',{buf=buf})
    while vim.fn.filereadable(realpath)==0 and vim.fn.isdirectory(realpath)==0 do
        realpath=vim.fn.fnamemodify(realpath,':h')
    end
    cmd=cmd..(vim.fn.isdirectory(realpath)==1 and ' "' or ' --cmd "select_file ')..realpath..'"'
    vim.fn.termopen(cmd,{
        on_exit=function(_,_,_)
            if vim.fn.filereadable(file)==1 then
                vim.cmd.edit(vim.fn.readfile(file)[1])
                vim.fn.delete(file)
            else
                if M.conf.exit_if_single and #vim.fn.getbufinfo()==1 and vim.api.nvim_get_current_buf()==buf then vim.cmd.quitall() end
            end
            vim.cmd.bdelete{buf,bang=true}
        end
    })
    vim.cmd.startinsert()
end
function M.run(file)
    M.ranger(vim.fn.expand(file or '%'))
end
return M
