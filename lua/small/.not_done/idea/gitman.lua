local M={}
M.path=vim.fs.joinpath(vim.fn.stdpath('data') --[[@as string]],'gitman')
function M.update()
end
function M.install_and_run()
    local proc={}
    for _,p in ipairs(M.configs) do
        local url=type(p)=='string' and p or p[1]
        local name=url:gsub('.*/','')
        local path=vim.fs.joinpath(M.path,name)
        if not vim.uv.fs_stat(path) then
            table.insert(proc,vim.system({
                'git','clone','--depth=1',url,vim.fs.joinpath(M.path,name)
            },{},function()
                    if p.make then
                        vim.system(p.make,{cwd=vim.fs.joinpath(M.path,name)},function() p.run() p.run=nil end)
                    elseif p.run then
                        p.run() p.run=nil
                    end
                end))
        elseif p.run then
            p.run() p.run=nil
        end
    end
end
function M.setup(configs)
    M.configs=configs
    M.install_and_run()
end
if vim.dev then
    M.setup{
        {'https://github.com/altermo/ultimate-autopair.nvim',run=function ()
        end},
    }
end
return M
