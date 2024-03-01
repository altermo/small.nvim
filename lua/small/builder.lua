local M={conf={builders={
    python={normal='python %s',source='pyfile %'},
    mojo={normal='mojo %s'},
    fish={normal='fish %s'},
    lua={normal='luajit %s',source='source'},
    fennel={normal='fennel %s',source='lua dofile("/usr/share/lua/5.4/fennel.lua").dofile(vim.fn.expand("%"))'},
    cs={normal='csharp %s',altern='dotnet run'},
    rust={normal='rustc %s -o __tmp;./__tmp;rm __tmp',alter='cargo run'},
    cpp={normal='zig c++ -O2 %s -o __tmp;./__tmp;rm __tmp'},
    c={normal='zig cc -O2 %s -o __tmp;./__tmp;rm __tmp',alter='make'},
    vim={source='source'},
    zig={normal='zig run %s',alter='zig build run'},
}}}

function M.eval()
    vim.cmd('silent! update')
    local builder=M.conf.builders[vim.o.filetype]
    if not builder or not builder.source then M.deferr() return end
    vim.dev=true vim.cmd(builder.source) vim.dev=nil
end
function M.termbuild()
    vim.cmd('silent! update')
    local builder=M.conf.builders[vim.o.filetype]
    if not builder or not builder.normal then M.deferr() return end
    M.open(builder.normal:format(vim.fn.expand('%:p:t')),vim.fn.expand('%:h'))
end
function M.open(src,cwd)
    if not M.win or not vim.api.nvim_win_is_valid(M.win) then
        vim.cmd.vsplit()
        M.win=vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(M.win,vim.api.nvim_create_buf(true,true))
        vim.cmd.startinsert()
    else
        local buf=vim.api.nvim_win_get_buf(M.win)
        vim.api.nvim_win_set_buf(M.win,vim.api.nvim_create_buf(true,true))
        vim.api.nvim_buf_delete(buf,{force=true})
    end
    vim.api.nvim_win_call(M.win,function()
        vim.fn.termopen(src,{cwd=cwd})
    end)
end
function M.deferr() vim.notify('Builderror: filetype '..vim.o.ft..' has no builder or can not be built or swapped') end
function M.swap()
    local s=M.conf.builders[vim.o.filetype]
    if not s or not s.altern then M.deferr() return end
    s.normal,s.altern=s.altern,s.normal
    vim.notify(('builder swapped from `%s` `to` `%s`'):format(s.altern,s.normal))
end
function M.set()
    M.conf.builders[vim.o.filetype].normal=vim.fn.input('>')
end
return M
