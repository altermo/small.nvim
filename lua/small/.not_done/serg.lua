local M={}
function M.run()
    local buf=vim.api.nvim_create_buf(false,true)
    vim.bo[buf].bufhidden='wipe'
    vim.api.nvim_create_autocmd({'TextChangedI','TextChanged'},{
        buffer=buf,
        callback=function ()
            if M.job then M.job:kill(0) end
            vim.api.nvim_buf_set_lines(buf,6,-1,false,{})
            local cmd={'rg','-n','--heading'}
            for path in vim.gsplit(vim.api.nvim_buf_get_lines(buf,4,5,false)[1]:gsub('.-:',''),',',{trimempty=true}) do
                table.insert(cmd,'-g')
                table.insert(cmd,path)
            end
            local search=vim.api.nvim_buf_get_lines(buf,1,2,false)[1]:gsub('.-:','')
            local sedsearch=vim.api.nvim_buf_get_lines(buf,2,3,false)[1]:gsub('.-:','')
            if search=='' then return end
            if sedsearch=='' then sedsearch=search end
            local replace=vim.api.nvim_buf_get_lines(buf,3,4,false)[1]:gsub('.-:','')
            table.insert(cmd,'--')
            table.insert(cmd,search)
            M.job=vim.system(cmd,{},vim.schedule_wrap(function (ev)
                vim.api.nvim_buf_set_lines(buf,-1,-1,false,vim.split(ev.stdout,'\n'))
            end))
        end
    })
    vim.api.nvim_buf_set_lines(buf,0,-1,false,{'','search (rg):','search (sed):','replace (sed):','path:',''})
    vim.cmd.vsplit()
    vim.api.nvim_set_current_buf(buf)
end
-- if vim.dev then
    M.run()
-- end
return M
