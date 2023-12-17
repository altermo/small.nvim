local M={var={}}
---TODO: use ColorSchemePre to make switching colors while running not cause problems
function M.get_colorscheme(colorname)
    local user_colorscheme=vim.g.colors_name
    vim.cmd.colorscheme(colorname)
    local save=vim.api.nvim_get_hl(0,{})
    vim.cmd.colorscheme(user_colorscheme)
    return save
end
function M.fill_colors(tbl,has)
    for k,_ in pairs(has) do
        if not tbl[k] then
            tbl[k]=false
        end
    end
    local _rep=0
    repeat
        local mayble_linked=false
        for k,v in pairs(tbl) do
            if type(v)=='table' and v.link then
                if tbl[v.link] then
                    if v.link==k then
                        if has[v.link] and has[v.link].link~=v.link then
                            tbl[k]=has[v.link]
                            mayble_linked=true
                        else
                            tbl[k]=nil
                        end
                    else
                        tbl[k]=tbl[v.link]
                        mayble_linked=true
                    end
                elseif has[v.link] then
                    if has[v.link].link~=v.link then
                        tbl[k]=has[v.link]
                        mayble_linked=true
                    else
                        tbl[k]=nil
                    end
                elseif vim.startswith(v.link,'@') and v.link:match('%.') then
                    tbl[k]={link=v.link:match('(.*)%.')}
                    mayble_linked=true
                else
                    if has[k] and has[k]~=v then
                        tbl[k]=has[k]
                        mayble_linked=true
                    else
                        tbl[k]=nil
                    end
                end
            elseif v==false then
                if has[k] then
                    tbl[k]=has[k]
                    mayble_linked=true
                elseif vim.startswith(k,'@') and k:match('%.') then
                    tbl[k]={link=k:match('(.*)%.')}
                    mayble_linked=true
                else
                    tbl[k]=nil
                end
            end
        end
        _rep=_rep+1
        if _rep>100 then error() end
    until not mayble_linked
end
function M.zip_colors(colornamefrom,colornameto)
    local from=M.get_colorscheme(colornamefrom)
    local to=M.get_colorscheme(colornameto)
    M.fill_colors(to,from)
    M.fill_colors(from,to)
    local ret={}
    for k,v in pairs(from) do
        ret[k]={from=v}
        assert(not v.link)
    end
    for k,v in pairs(to) do
        ret[k].to=v
        assert(not v.link)
    end
    return ret
end
function M.hex_to_number(hex)
    if type(hex)=='number' then hex=('#%06x'):format(hex) end
    local r,g,b=hex:match('#(..)(..)(..)')
    return tonumber(r,16),tonumber(g,16),tonumber(b,16)
end
function M.number_to_hex(r,g,b)
    return string.format('#%02x%02x%02x',r,g,b)
end
function M.set_color(name,from,to,p)
    local val
    if p<0.5 then val={bold=from.bold}
    else val={bold=to.bold} end
    if from.fg and to.fg then
        local rf,gf,bf=M.hex_to_number(from.fg)
        local rt,gt,bt=M.hex_to_number(to.fg)
        val.fg=M.number_to_hex(rt*p+rf*(1-p),gt*p+gf*(1-p),bt*p+bf*(1-p))
    else
        val.fg=from.fg or to.fg
    end
    if from.bg and to.bg then
        local rf,gf,bf=M.hex_to_number(from.bg)
        local rt,gt,bt=M.hex_to_number(to.bg)
        val.bg=M.number_to_hex(rt*p+rf*(1-p),gt*p+gf*(1-p),bt*p+bf*(1-p))
    else
        val.bg=from.bg or to.bg
    end
    vim.api.nvim_set_hl(0,name,val)
end
function M.update()
    for k,v in pairs(M.var.colors) do
        M.set_color(k,v.from,v.to,M.var.step/M.var.steps)
    end
end
function M.async_run(colors,time,steps,from,to)
    vim.cmd.colorscheme(from)
    local step=1
    local stop_flag=false
    local au=vim.api.nvim_create_autocmd('ColorSchemePre',{callback=function (ev)
        if ev.match~='_color_shift' then stop_flag=true end
    end})
    local function t()
        if stop_flag then
            vim.api.nvim_del_autocmd(au)
            return
        end
        if step==steps then
            vim.api.nvim_del_autocmd(au)
            vim.cmd.colorscheme(to)
            return
        end
        step=step+1
        M.var.step=step
        M.var.steps=steps
        M.var.colors=colors
        --TODO: make work for lualine
        vim.cmd.colorscheme('_color_shift')
        vim.defer_fn(t,time/steps)
    end
    t()
end
function M._shift(colornamefrom,colornameto,time,steps)
    vim.schedule(function ()
        local colors=M.zip_colors(colornamefrom,colornameto)
        M.async_run(colors,time,steps,colornamefrom,colornameto)
    end)
end
function M.shift(colorname,time,steps)
    M._shift(vim.g.colors_name,colorname,time,steps or 10)
end
if vim.dev then
    vim.dev=false
    package.loaded['small.color_shift']=nil
    if vim.g.colors_name=='nordfox' then
        require'small.color_shift'.shift('tokyonight',1000)
    else
        require'small.color_shift'.shift('nordfox',1000)
    end
end
return M
