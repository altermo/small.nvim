local M={}
M.builders={
    python={normal='python %s',source='pyfile %'},
    mojo={normal='mojo %s'},
    fish={normal='fish %s'},
    lua={normal='lua5.1 %s',source='luafile %'},
    fennel={normal='fennel %s',source='lua dofile("/usr/share/lua/5.4/fennel.lua").dofile(vim.fn.expand("%"))'},
    cs={normal='dotnet run',altern='csharp %s'},
    rust={normal='rustc %s -o __tmp;./__tmp;rm __tmp',alter='cargo run'},
    cpp={normal='zig c++ -O2 %s -o __tmp;./__tmp;rm __tmp'},
    c={normal='zig cc -O2 %s -o __tmp;./__tmp;rm __tmp',alter='make'},
    vim={source='so %'},
    zig={normal='zig run %s',alter='zig build run'},
}
function M.eval()
    vim.cmd('silent! update')
    local builder=M.builders[vim.o.filetype]
    if not builder or not builder.source then M.deferr() return end
    vim.dev=true vim.cmd(builder.source) vim.dev=nil
end
--function M.build()
--vim.cmd('silent! update')
--local builder=M.builders[vim.o.filetype]
--if not builder or not builder.normal then M.deferr() return end
--TODO: build in quickfix window
--end
function M.termbuild()
    vim.cmd('silent! update')
    local builder=M.builders[vim.o.filetype]
    if not builder or not builder.normal then M.deferr() return end
    vim.cmd.vnew()
    vim.fn.termopen(builder.normal:format(vim.fn.expand('#:p:t')),{cwd=vim.fn.expand('#:h')})
    vim.cmd.startinsert()
end
function M.deferr() vim.notify('Builderror: filetype '..vim.o.ft..' has no builder or can not be built or swaped') end
function M.swap()
    local s=M.builders[vim.o.filetype]
    if not s or not s.altern then M.deferr() return end
    s.normal,s.altern=s.altern,s.normal
    vim.notify(('builder swaped from `%s` `to` `%s`'):format(s.altern,s.normal))
end
function M.set()
    M.builders[vim.o.filetype].normal=vim.fn.input('>')
end
return M
