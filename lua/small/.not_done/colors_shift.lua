local M={}
---TODO: use ColorSchemePre to make switching colors while runing not cause problems
function M.get_colorscheme(colorname)
    local user_colorscheme=vim.g.colors_name
    local colorfile=unpack(vim.api.nvim_get_runtime_file('colors/'..colorname..'.*',false))
    if not colorfile then error('colorscheme '..colorname..' not found') end
    local backup=vim.api.nvim_set_hl
    local save={}
    local s,err=pcall(function()
        rawset(vim.api,'nvim_set_hl',function (_,name,val)
            save[name]=val
        end)
        vim.cmd.source(colorfile)
    end)
    if not s then error(err) end
    rawset(vim.api,'nvim_set_hl',backup)
    vim.cmd.colorscheme(user_colorscheme)
    return save
end
function M.handle_color(val,colors)
    while val.link do
        local link=val.link
        val.link=nil
        val=vim.tbl_extend('force',val,colors[link] or {})
    end
    if val.fg and not vim.startswith(val.fg,'#') then
        val.fg=val.fg~='NONE' and string.format('#%06X',vim.api.nvim_get_color_map()[val.fg]) or nil
    end
    if val.bg and not vim.startswith(val.bg,'#') then
        val.bg=val.bg~='NONE' and string.format('#%06X',vim.api.nvim_get_color_map()[val.bg]) or nil
    end
    val.default=false
    return val
end
function M.zip(tbl_a,tbl_b)
    local ret={}
    for k,v in pairs(tbl_a) do
        ret[k]={from=M.handle_color(v,tbl_a)}
    end
    for k,v in pairs(tbl_b) do
        if not ret[k] then ret[k]={} end
        ret[k].to=M.handle_color(v,tbl_b)
    end
    return ret
end
function M.hex_to_number(hex)
    local r,g,b=hex:match('#(..)(..)(..)')
    return tonumber(r,16),tonumber(g,16),tonumber(b,16)
end
function M.number_to_hex(r,g,b)
    return string.format('#%02x%02x%02x',r,g,b)
end
---@param from vim.api.keyset.highlight
---@param to vim.api.keyset.highlight
function M.set_color(name,from,to,p)
    local perecent=p*100
    local val={
        bold=perecent<50 and from.bold or to.bold,
    }
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
function M.co_run(colors,time,steps,from,to)
    local co=coroutine.running()
    vim.cmd.colorscheme(from)
    for step=1,steps do
        vim.defer_fn(function () coroutine.resume(co) end,time/steps)
        coroutine.yield()
        for k,v in pairs(colors) do
            local s,err=pcall(M.set_color,k,v.from or {},v.to or {},step/steps)
            if not s then vim.notify(err or 'nil',vim.log.levels.ERROR) coroutine.yield() end
        end
    end
    vim.cmd.colorscheme(to)
end
function M._shift(colornamefrom,colornameto,time,steps)
    local colors=M.zip(M.get_colorscheme(colornamefrom),M.get_colorscheme(colornameto))
    coroutine.wrap(M.co_run)(colors,time,steps,colornamefrom,colornameto)
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
