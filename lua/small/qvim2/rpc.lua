local M={}
function M.exec(rpc,code,args)
    if not _G.UA_DEV then
        vim.rpcnotify(rpc,'nvim_exec_lua',code,args or {})
    end
    vim.rpcnotify(rpc,'nvim_exec_lua',[[
    local code,args,server,traceback=...
    local function send_err(msg,level)
        local rpc=vim.fn.sockconnect('pipe',server,{rpc=true})
        vim.rpcnotify(rpc,'nvim_echo',{{'(qvim2) DEVELEPOR error:\n','WarningMsg'},{msg..traceback,'ErrorMsg'}},false,{})
    end
    local fn,msg=loadstring(code)
    if msg then send_err(msg) return end
    xpcall(fn,function (msg) send_err(msg) end,unpack(args))
    ]],{code,args or {},vim.v.servername,debug.traceback('',2)})
end
function M.start(opts)
    opts=opts or {}
    local cmd={vim.v.progpath,'--embed','--headless','-n'}
    if opts.noconf then
        table.insert(cmd,'--clean')
    end
    return vim.fn.jobstart(cmd,{rpc=true})
end
function M.load_file_async(rpc,file,opts)
    opts=opts or {}
    M.exec(rpc,[[
    local file,server,propagate_error=...
    local function send_err(msg,level,pre)
        local rpc=vim.fn.sockconnect('pipe',server,{rpc=true})
        vim.rpcnotify(rpc,'nvim_echo',{{'Plugin `qvim2` had an error:\n'..pre..'\n\n','WarningMsg'},{debug.traceback(msg,level),'ErrorMsg'}},false,{})
    end
    local fn,msg=loadfile(file)
    if msg then
        if propagate_error then
            send_err(msg,1,'Incorrect syntax in file:\n'..file)
        end
        vim.api.nvim_echo({{debug.traceback(msg,1),'ErrorMsg'}},true,{})
        return
    end
    if not propagate_error then
        fn()
        return
    end
    local s,msg=xpcall(fn,function (msg)
        send_err(msg,3,'Error while (remotely) executing file:\n'..file)
        return debug.traceback(msg,1)
    end)
    if not s then
        vim.api.nvim_echo({{msg,'ErrorMsg'}},true,{})
    end
    ]],{file,vim.v.servername,opts.propagate_error})
end
function M.open_in_buf(rpc)
    local server=vim.rpcrequest(rpc,'nvim_get_vvar','servername')
    vim.fn.termopen({'nvim','--remote-ui','--server',server})
end
function M.stop(rpc)
    pcall(vim.fn.jobstop,rpc)
end
return M
