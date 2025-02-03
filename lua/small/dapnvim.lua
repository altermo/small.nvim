local M={}
local function get_rtp_by(file)
    local path=vim.api.nvim_get_runtime_file(file,false)[1]
    if not path then return end
    return path:gsub(vim.pesc(file),'')
end
function M.job_start_nvim()
    local function fall()
        return vim.fn.jobstart({'nvim','--headless','--embed'},{rpc=true}),function(nvim)
            vim.rpcnotify(nvim,'nvim_command','luafile '..vim.fn.expand'%:p')
        end
    end
    local dir=vim.fs.find({'.git'},{upward=true})[1]
    if not dir then return fall() end
    dir=vim.fs.dirname(dir)
    if vim.fn.filereadable(vim.fs.joinpath(dir,'dapnvim.lua'))==0 then return fall() end
    local job=vim.fn.jobstart({'nvim','--headless','--embed','--clean','-n'},{rpc=true})
    vim.rpcrequest(job,'nvim_exec_lua',[[
    local file1,file2=...
    vim.opt.rtp:append(file1)
    vim.opt.rtp:append(file2)
    ]],{
            get_rtp_by('lua/osv'),
            get_rtp_by('lua/dap'),
        })
    return job,function(nvim)
        vim.rpcnotify(nvim,'nvim_exec_lua',[[
        local file=...
        loadfile(file)()
        ]],{vim.fs.joinpath(dir,'dapnvim.lua')})
    end
end
function M.start_nvim()
    if M.nvim then
        vim.fn.jobstop(M.nvim)
    end
    local nvim,run=M.job_start_nvim()
    M.nvim=nvim
    vim.rpcrequest(nvim,'nvim_exec_lua',[[
    local file1,file2=...
    require'osv'.launch({port=8086,args={
        '-c','set rtp+='..file1
    }})
    ]],{get_rtp_by('lua/osv')})
    vim.wait(100)
    local dap=require'dap'
    dap.run({type='nlua',request='attach'})
    dap.listeners.after['setBreakpoints']['dapnvim']=function ()
        run(nvim)
    end
    return vim.rpcrequest(nvim,'nvim_get_vvar','servername')

end
function M.start()
    M.prevbuf=M.buf
    M.buf=vim.api.nvim_create_buf(false,true)
    vim.bo[M.buf].bufhidden='wipe'
    if M.prevbuf and vim.api.nvim_buf_is_valid(M.prevbuf) then
        for _,w in ipairs(vim.fn.win_findbuf(M.prevbuf)) do
            vim.api.nvim_win_set_buf(w,M.buf)
        end
    else
        vim.api.nvim_open_win(M.buf,false,{split='right'})
    end
    local server_path=M.start_nvim()
    vim.api.nvim_buf_call(M.buf,function ()
        vim.cmd.term(table.concat({'nvim','--remote-ui','--server',server_path},' '))
    end)
end
return M
