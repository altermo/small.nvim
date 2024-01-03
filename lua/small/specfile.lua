local M={}
M.conf={
    ext={
        org='emacs',
        mp3='sound',
        png='image',
        jpg='image',
        mp4='video',
        gif='video',
        pdf='browser',
    },
    prgm={
        sound={'firefox',async=true},
        video={'firefox',async=true},
        image={'firefox',async=true},
        browser={'firefox',async=true},
        bigfile={'nvim','-n','--clean','--'},
        emacs={'emacsclient','-c','-a','emacs','-nw','--'},
    },
    bigfile=4*1024*1024,
    startinsert=true,
}
---@param prgm {[number]:string,async:boolean?,name:string?}
---@param file string
function M.run_prgm(prgm,file)
    local p=vim.deepcopy(prgm,true)
    table.insert(p,file)
    local buf=vim.api.nvim_get_current_buf()
    if prgm.async then
        vim.system(p,{detach=true})
        local mesbuf=vim.api.nvim_create_buf(false,true)
        vim.bo[mesbuf].bufhidden='wipe'
        vim.api.nvim_buf_set_lines(mesbuf,0,-1,false,{'File opened in: '..(p.name or p[1])})
        vim.api.nvim_win_set_buf(0,mesbuf)
        vim.api.nvim_buf_delete(buf,{force=true})
        vim.api.nvim_buf_set_name(mesbuf,file)
        return
    end
    vim.fn.termopen(p,{on_exit=function() pcall(vim.cmd.bdelete,{buf,bang=true}) end})
    vim.api.nvim_buf_set_name(0,file)
    if M.conf.startinsert then vim.api.nvim_feedkeys(vim.keycode'<cmd>startinsert\r','n',false) end
end
function M.setup()
    M.au_group=vim.api.nvim_create_augroup('small.spec_file',{})
    vim.api.nvim_create_autocmd('BufReadPre',{group=M.au_group,callback=function (ev)
        local ext=vim.fn.fnamemodify(ev.file,':e')
        if M.conf.ext[ext] then
            M.run_prgm(M.conf.prgm[M.conf.ext[ext]],ev.file)
        elseif M.conf.bigfile and vim.uv.fs_stat(ev.file) and vim.uv.fs_stat(ev.file).size>=M.conf.bigfile then
            M.run_prgm(M.conf.prgm.bigfile,ev.file)
            vim.notify('file to big')
        end
    end})
end
if vim.dev then
    M.setup()
end
return M
