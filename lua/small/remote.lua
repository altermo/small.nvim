local M={ns=vim.api.nvim_create_namespace('small-remote')}
function M.run(file)
    if not file then
        vim.ui.input({prompt=':'}, function(input)
            file=input
            if vim.fn.filereadable(file)==0 then
                file='/run/user/'..vim.uv.getuid()..'/nvim.'..input..'.0'
            end
            if vim.fn.filereadable(file)==0 then
                file='/run/user/'..vim.uv.getuid()..'/nvim.'..((tonumber(input) or -2)+1)..'.0'
            end
            if vim.fn.filereadable(file)==0 then
                error('socket for '..input..' not found')
            end
            M.run(file)
        end)
        return
    end
    local buf=vim.api.nvim_create_buf(false,true)
    vim.bo[buf].bufhidden='wipe'
    vim.bo[buf].buftype='prompt'
    local chan=vim.fn.sockconnect('pipe',file,{rpc=true})
    vim.fn.prompt_setcallback(buf,function (inp)
        if inp=='@input' then
            local ibuf=vim.api.nvim_create_buf(false,true)
            vim.bo[buf].bufhidden='wipe'
            vim.api.nvim_open_term(ibuf,{})
            vim.on_key(function (key)
                vim.rpcrequest(chan,'nvim_input',vim.fn.keytrans(key))
            end,M.ns)
            vim.schedule(vim.cmd.startinsert)
            local win=vim.api.nvim_open_win(ibuf,true,{
                relative='win',
                width=10,height=10,
                row=0,col=0,
                style='minimal',
            })
            vim.api.nvim_create_autocmd('TermLeave',{callback=function ()
                vim.api.nvim_win_close(win,true)
                vim.on_key(nil,M.ns)
            end,once=true})
        elseif vim.startswith(inp,'@input') then
            inp=inp:sub(8)
            vim.rpcrequest(chan,'nvim_input',inp)
        elseif inp~='' then
            ---@diagnostic disable-next-line: undefined-field
            if vim.rpcrequest(chan,'nvim_get_mode').blocking then
                vim.api.nvim_buf_set_lines(buf,-2,-1,false,{'Input blocking, async send'})
                vim.rpcnotify(chan,'nvim_exec2',inp,{})
                return
            end
            local noerr,msg=pcall(function ()
                ---@diagnostic disable-next-line: undefined-field
                local output=vim.rpcrequest(chan,'nvim_exec2',inp,{output=true}).output
                vim.api.nvim_buf_set_lines(buf,-2,-1,false,vim.split(output,'\n'))
            end)
            if not noerr then
                vim.api.nvim_buf_set_lines(buf,-2,-1,false,vim.split(msg or '','\n'))
            end
        end
    end)
    vim.cmd.vsplit()
    vim.api.nvim_set_current_buf(buf)
end
return M
