local M={conf={path=vim.fs.joinpath(vim.fn.stdpath('data') --[[@as string]],'/help_readme')}}
M.ext2ft={md='markdown'}
---@param dirs? string[]
function M.generate(dirs)
    local docdir=vim.fs.joinpath(M.conf.path,'/doc')
    vim.fn.mkdir(docdir,'p')
    for i in vim.fs.dir(docdir) do
        os.remove(vim.fs.joinpath(docdir,i))
    end
    dirs=dirs or vim.api.nvim_get_runtime_file('',true)
    local readmes={}
    local regex=vim.regex[[\creadme.]]
    for _,dir in ipairs(dirs) do
        local readme=unpack(vim.fs.find(function(str) return not not regex:match_str(str) end,{path=dir,limit=1}))
        if readme then table.insert(readmes,readme) end
    end
    for _,readme in ipairs(readmes) do
        local lines=vim.fn.readfile(readme)
        local ext=vim.fn.fnamemodify(readme,':e')
        table.insert(lines,('<!-- vim: set ft=%s: -->'):format(M.ext2ft[ext] or ext))
        vim.fn.writefile(lines,vim.fs.joinpath(docdir,vim.fn.fnamemodify(readme,':h:t')..'-readme.'..ext))
    end
    vim.system({'ctags','--fields=','-R','.'},{cwd=docdir}):wait()
    local lines=vim.fn.readfile(vim.fs.joinpath(docdir,'tags'))
    for k,v in pairs(lines) do
        if v:sub(1,1)~='!' then
            lines[k]=v:gsub('^(.-)\t(.-)(%-readme.-)\t','readme-%2-%1\t%2%3\t')
        end
    end
    vim.fn.writefile(lines,vim.fs.joinpath(docdir,'tags'))

end
function M.setup()
    vim.opt.runtimepath:append(M.conf.path)
end
if vim.dev then
    local dir='/home/user/.local/share/nvim/site/pack/pckr/opt/'
    local dirs=vim.api.nvim_get_runtime_file('',true)
    for i in vim.fs.dir(dir) do
        if not vim.tbl_contains(dirs,vim.fs.joinpath(dir,i)) then
            table.insert(dirs,vim.fs.joinpath(dir,i))
        end
    end
    M.generate(dirs)
    M.setup()
end
return M
