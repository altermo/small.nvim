--TODO: add write-good (only in comments/markdown)
local M={
    ns_typos=vim.api.nvim_create_namespace'small_typo_typos',
    ns_codespell=vim.api.nvim_create_namespace'small_codespell_typos',
    job={}
}
function M.update_typos(buf)
    if M.job.typos then M.job.typos:wait() end
    local lines=vim.api.nvim_buf_get_lines(buf,0,-1,false)
    M.job.typos=vim.system({'typos','-','--format=json'},{stdin=lines},vim.schedule_wrap(function (ev)
        if not vim.api.nvim_buf_is_valid(buf) then return end
        vim.diagnostic.set(M.ns_typos,buf,vim.iter(vim.split(ev.stdout,'\n',{trimempty=true})):map(vim.json.decode):map(function (json)
            return {
                col=json.byte_offset,
                end_col=json.byte_offset+#json.typo,
                lnum=json.line_num-1,
                message=('typos: `%s` => `%s`'):format(json.typo,table.concat(json.corrections,'`, `')),
                severity=vim.diagnostic.severity.HINT,
            }
        end):totable())
    end))
end
function M.update_codespell(buf)
    local lines=vim.api.nvim_buf_get_lines(buf,0,-1,false)
    if M.job.codespell then M.job.codespell:wait() end
    M.job.codespell=vim.system({'codespell','-','--builtin','clear,rare,informal,names'},{stdin=lines},vim.schedule_wrap(function (ev)
        if not vim.api.nvim_buf_is_valid(buf) then return end
        local iter=vim.iter(vim.split(ev.stdout,'\n',{trimempty=true}))
        local diagnostics={}
        local has={}
        while iter:peek() do
            local lnum=assert(tonumber(iter:next():match('^(%d+):')))
            has[lnum]=has[lnum] or {}
            local word,spell=iter:next():match('\t(%S+) ==> (.*)')
            local spells=vim.split(spell,', ')
            local col=lines[lnum]:find(word,has[lnum][word] or 0,true)
            has[lnum][word]=col+1
            table.insert(diagnostics,{
                col=col-1,
                end_col=col+#word-1,
                lnum=lnum-1,
                message=('codespell: `%s` => `%s`'):format(word,table.concat(spells,'`, `')),
                severity=vim.diagnostic.severity.HINT,
            })
        end
        vim.diagnostic.set(M.ns_codespell,buf,diagnostics)
    end))
end
function M.update(buf)
    buf=buf or 0
    if vim.api.nvim_buf_line_count(buf)>100000 then return end
    if vim.fn.executable('typos')==1 then
        M.update_typos(buf)
    end
    if vim.fn.executable('codespell')==1 then
        M.update_codespell(buf)
    end
end
function M.setup()
    local timer
    vim.schedule(function ()
        vim.api.nvim_create_autocmd({'TextChanged','InsertLeave','BufEnter'},{callback=function (ev)
            if timer then timer:stop() end
            timer=vim.defer_fn(function ()
                if vim.bo[ev.buf].spelllang~='en' then
                    vim.diagnostic.set(M.ns_typos,ev.buf,{})
                    vim.diagnostic.set(M.ns_codespell,ev.buf,{})
                elseif vim.bo[ev.buf].buftype~='terminal' then
                    M.update(ev.buf)
                end
            end,100)
        end,group=vim.api.nvim_create_augroup('small_typos',{clear=true})})
    end)
end
if vim.dev then
    M.setup()
end
return M
