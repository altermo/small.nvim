local M={conf={},ns=vim.api.nvim_create_namespace'small_treewarn'}
function M.update(buf)
    buf=buf or 0
    local s,parser=pcall(vim.treesitter.get_parser,buf)
    if not s then return end
    if not M.conf[vim.bo[buf].filetype] then return end
    local query=vim.treesitter.query.parse(vim.bo[buf].filetype,table.concat(M.conf[vim.bo[buf].filetype],'\n'))
    local trees=parser:parse()
    local diagnostics={}
    for id,node,meta in query:iter_captures(trees[1]:root(),buf,0,-1) do
        local srow,scol,erow,ecol=node:range()
        table.insert(diagnostics,{
            col=scol,
            end_col=ecol,
            lnum=srow,
            end_lnum=erow,
            message=meta.mes or 'treewarn',
            severity=vim.diagnostic.severity[query.captures[id]:upper()],
        })
    end
    vim.diagnostic.set(M.ns,buf,diagnostics)
end
function M.setup()
    vim.schedule(function ()
        vim.api.nvim_create_autocmd({'TextChanged','InsertLeave','BufEnter'},{callback=function (ev)
            M.update(ev.buf)
        end,group=vim.api.nvim_create_augroup('small_treewarn',{clear=true})})
    end)
end
if vim.dev then
    M.conf.lua={'((binary_expression (unary_expression "not") "==") @warn (#set! "mes" "`not a==b` => `a~=b`"))'}
    M.setup()
end
return M
