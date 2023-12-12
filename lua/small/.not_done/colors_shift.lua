local M={}
---TODO: use ColorSchemePre to make switching colors while runing not cause problems
function M.get_colorscheme(colorname)
    local user_colorscheme=vim.g.colors_name
    vim.cmd.colorscheme(colorname)
    local save=vim.api.nvim_get_hl(0,{})
    vim.cmd.colorscheme(user_colorscheme)
    return save
end
function M.zip_colors(colornamefrom,colornameto)
    local from=M.get_colorscheme(colornamefrom)
    local to=M.get_colorscheme(colornameto)
    local ret={}
    for k,_ in pairs(from) do ret[k]={'tokyonight'} end
    for k,_ in pairs(to) do ret[k]={'nordfox',unpack(ret[k] or {})} end
    vim.lg(ret)
    return ret
end
function M._shift(colornamefrom,colornameto,time,steps)
    M.zip_colors(colornamefrom,colornameto)
    --coroutine.wrap(M.co_run)(colors,time,steps,colornamefrom,colornameto)
end
function M.shift(colorname,time)
    M._shift(vim.g.colors_name,colorname,time,10)
end
if vim.dev then
    if vim.g.colors_name=='nordfox' then
        M.shift('tokyonight',1000)
    else
        M.shift('nordfox',1000)
    end
end
return M
