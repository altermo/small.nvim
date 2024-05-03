local sep=',' --+,=@[]^
local uv=vim.uv or vim.loop
local rpc=require'small.qvim2.rpc'
--local conf={
    --force_rtp=true, --Error if can't set the runtimepath. Runtimepath is set to git repo or lua dir if found
    --propagate_error='all', --If there's an error propagate it to the user, valid options are 'all', 'ifhidden', 'never'
    --log_func=true, --Set a global log function which logs the value, if function then the function gets any number of arguments where the first is the builtin log function and everything else is the passed in arguments to the global log
    --log_file_limit=1000, --The maximum number of lines in the log file. NOTE: it is checked before logging a value, so if you log a value which is over 1000 lines, it will not be trimmed to 1000 lines.
    --run_options={
        --noconf=false,   --Don't load the users (or other) config file
        --conf='',        --Load config file at path (see |qvim2.path|)
    --},
--}
local M={}
function M.util_join(...)
    return (table.concat({...},'/'):gsub('//+','/'))
end
function M.get_data_path()
    local data=M.util_join(vim.fn.stdpath'data','/qvim2/')
    vim.fn.mkdir(data,'p')
    --if vim.fn.filereadable(M.join(data,'lua','fn.lua'))==0 then
    --vim.fn.mkdir(M.join(data,'lua'),'p')
    --uv.fs_symlink('./lua/qvim2/fn.lua',M.join(data,'lua','fn.lua'))
    --end
    return data
end
function M.get_root(nil_if_no_root)
    if vim.startswith(vim.fn.expand('%:p'),M.get_data_path()) then
        local path=vim.fn.expand('%:p')
        while vim.fs.basename(vim.fs.dirname(path))~='qvim2' do
            path=vim.fs.dirname(path)
            assert(path~='/','(qvim2) DEVELEPOR error: safety error against infinite loop')
        end
        return vim.fs.basename(path):gsub(sep,'/')
    end
    if vim.startswith(assert(uv.cwd()),M.get_data_path()) then
        local path=assert(uv.cwd())
        while vim.fs.basename(vim.fs.dirname(path))~='qvim2' do
            path=vim.fs.dirname(path)
            assert(path~='/','(qvim2) DEVELEPOR error: safety error against infinite loop')
        end
        return vim.fs.basename(path):gsub(sep,'/')
    end
    local cwd=assert(uv.cwd())
    local root=vim.fs.dirname(vim.fs.find('.git',{upward=true,path=cwd})[1])
    if not root then
        root=vim.fs.dirname(vim.fs.find('lua',{upward=true,path=cwd})[1])
    end
    if not root then
        return not nil_if_no_root and cwd or nil
    end
    return vim.fn.fnamemodify(root,':p:h')
end
function M.get_path()
    local path=M.util_join(M.get_data_path(),(M.get_root():gsub('/',sep)))
    vim.fn.mkdir(path,'p')
    return path
end
function M.get_run_file()
    local path=M.get_path()
    local file=M.util_join(path,'run.lua')
    if vim.fn.filereadable(file)==0 then vim.fn.writefile({
        '--- OPT1,OPT2,OPT3',
        '--- Specify your configuration in the first line',
        '--- For example to not load config use `noconf`',
        --'-- local fn=require"fn"',
        --'--- the fn module contains useful utils for debugging',
        '',
    },file)
    end
    return file
end
function M.open_run_buf()
    --local path=M.get_path()
    local file=M.get_run_file()
    --local root=M.get_root(true)
    --if root and uv.fs_readlink(M.join(path,'project'))~=root then
    --    uv.fs_symlink(root,M.join(path,'project'))
    --end
    vim.cmd.vsplit()
    vim.api.nvim_set_current_buf(vim.fn.bufadd(file))
end
function M.open_or_replace_buf(prevbuf)
    local buf=vim.api.nvim_create_buf(false,true)
    vim.bo[buf].bufhidden='wipe'
    if prevbuf and vim.api.nvim_buf_is_valid(prevbuf) and #vim.fn.win_findbuf(prevbuf)>0 then
        for _,w in ipairs(vim.fn.win_findbuf(prevbuf)) do
            vim.api.nvim_win_set_buf(w,buf)
        end
        pcall(vim.api.nvim_buf_delete,prevbuf,{force=true})
    else
        vim.cmd.vsplit()
        vim.api.nvim_set_current_buf(buf)
    end
    return buf
end
function M.run()
    M.rpcbuf=M.open_or_replace_buf(M.rpcbuf)
    rpc.stop(M.rpc)
    local run_file=M.get_run_file()
    local run_opts=vim.split(vim.fn.readfile(run_file,'')[1] or '','[^%w]',{trimempty=true})
    local opts={}
    for _,run_opt in ipairs(run_opts) do
        opts[run_opt]=true
    end
    M.rpc=rpc.start({noconf=opts.noconf})
    vim.api.nvim_buf_call(M.rpcbuf,function ()
        rpc.open_in_buf(M.rpc)
    end)
    if opts.debug then
        if pcall(require,'osv') and pcall(require,'dap') then
            M.init_osv(8086)
        end
    end
    rpc.exec(M.rpc,[[vim.opt.runtimepath:prepend(...)]],{M.get_root()})
    rpc.load_file_async(M.rpc,run_file,{propagate_error=true})
end
function M.util_require_to_path(name)
    return vim.fs.dirname(vim.fs.dirname(assert(vim.api.nvim_get_runtime_file('lua/'..name,false)[1])))
end
function M.init_osv(port)
    rpc.exec(M.rpc,[[
    local port,osvpath,dappath=...
    vim.opt.runtimepath:prepend(osvpath)
    vim.opt.runtimepath:prepend(dappath)
    local osv=require'osv'
    vim.print(osv)
    osv.launch({port = 8086,args={
        '-c','set rtp+='..osvpath
    }})
    ]],{port,M.util_require_to_path('osv'),M.util_require_to_path('dap')})
    vim.wait(50)
    require'dap'.continue()
    vim.wait(100)
end
return M
