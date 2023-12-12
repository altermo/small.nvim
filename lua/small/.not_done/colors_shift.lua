local M={}
---TODO: use ColorSchemePre to make switching colors while runing not cause problems
function M.get_colorscheme(colorname)
    local user_colorscheme=vim.g.colors_name
    vim.cmd.colorscheme(colorname)
    local save=vim.api.nvim_get_hl(0,{})
    vim.cmd.colorscheme(user_colorscheme)
    return save
end
function M.zip_colors(tbl_a,tbl_b)
    local ret={}
    for k,_ in pairs(tbl_a) do ret[k]={'tokyonight'} end
    for k,_ in pairs(tbl_b) do ret[k]={'nordfox',unpack(ret[k] or {})} end
    vim.lg(ret)
    return ret
end
function M._shift(colornamefrom,colornameto,time,steps)
    local colors=M.zip_colors(M.get_colorscheme(colornamefrom),M.get_colorscheme(colornameto))
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
