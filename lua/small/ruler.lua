local M={}
function M.MyRuler()
    local out=''
    if vim.fs.root(0,'.git') then
        local c=vim.system({'git','rev-parse','--abbrev-ref','HEAD'}):wait()
        if c.code==0 then
            out=out..('%s '):format(vim.trim(c.stdout))
        end
    end
    local s={}
    for _,v in ipairs(vim.diagnostic.get(0)) do
        s[v.severity]=(s[v.severity] or 0)+1
    end
    for i,v in vim.spairs(s) do
        i=({ERROR='󰅚 ',WARN='󰀪 ',INFO='󰋽 ',HINT='󰌶 '})[vim.diagnostic.severity[i]]
        out=out..('%s%d '):format(i,v)
    end
    return out..'%t %=%l,%c%V %=%P'
end
function M.setup()
    _G.MyRuler=M.MyRuler
    local old_columns=-1
    local function refresh()
        if old_columns==vim.o.columns then return end
        old_columns=vim.o.columns
        if (vim.o.columns-60-12)>50 then
            vim.o.rulerformat='%60(%{%v:lua.MyRuler()%}%)'
            vim.o.ruler=true
        elseif (vim.o.columns-40-12)>50 then
            vim.o.rulerformat='%40(%{%v:lua.MyRuler()%}%)'
            vim.o.ruler=true
        elseif (vim.o.columns-15-12)>50 then
            vim.o.rulerformat='%l,%c%V %=%P'
            vim.o.ruler=true
        else
            vim.o.ruler=false
        end
        vim.cmd.mode()
    end
    vim.api.nvim_create_autocmd('WinResized',{callback=refresh})
    refresh()
end
return M











































