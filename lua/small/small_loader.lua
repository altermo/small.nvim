local M={}
M.conf={}
M.loaded={}
M.def={
    fork={special=true},
    lib={special=true},
    small_loader={special=true},

    color_cmdline={setup=true,event={'CmdlineEnter'}},
    cursor_xray={setup=true,event={'WinNew'}},
    elastic_tabstop={setup=true,event={'~Now'}},
    foldtext={setup=true,conf=true,event={'~Fold'}},
    help_readme={setup=true,build='generate',conf=true,event={'~Now'}},
    highlight_selected={setup=true,event={'~VisualEnter'}},
    labull={setup=true,event={'~OnKey'}},
    specfile={setup=true,conf=true,event={'BufReadPre'}},
    statusbuf={setup=true,event={'~Now'}},
    tabline={setup=true,event={'TabNew'}},
    treewarn={setup=true,conf=true,event={'~Later'}},
    typo={setup=true,event={'~Later'}},
    winvis={setup=true,event={'~VisualEnter'}},
    zenall={setup=true,event={'~Now'}},
    large={setup='start',event={'~Now'}},
    beacon={setup='create_autocmd',conf=true,event={'~Now'}},
    debugger={setup='override_error',event={'~Now'}},

    own={setup=true,run='load',event={'~Now'}},
    matchall={setup=true,run='toggle',event={'~Later'}},
    cursor={setup=true,run={'create_cursor','goto_next_cursor','clear_cursor'},conf=true,event={'BufNew'}},
    kitty={setup=true,run={'set_font_size','get_font_size','set_padding','toggle_padding'},conf=true,event={'~Now'}},
    reminder={setup=true,run='sidebar',conf=true,event={'~Later'}},
    notify={setup='override_notify',run={'notify','open_history','dismiss'},conf=true,event={'~Now'}},
    copyring={setup=true,run={'put','cycle'},keys=function (m,fn)
        fn.map('n','p',function () m.put(true) end)
        fn.map('n','P',function () m.put(false) end)
        fn.map('n','<A-p>',function () m.cycle(false) end)
        fn.map('n','<A-P>',function () m.cycle(true) end)
    end,event={'~OnKey'}},

    bufend={run=true},
    chat={run=true},
    foldselect={run=true},
    format={run=true},
    nterm={run=true},
    lbpr={run=true},
    plugin_search={run=true},
    qrun={run=true},
    tableformat={run=true},
    recenter_top_bottom={run=true},
    zen={run=true},
    ranger={run={'run','ranger'},conf=true},
    jumpall={run=true,conf=true},
    iedit={run={'clear','visual_all','visual_select'}},
    cmd2ins={run='map'},
    color_shift={run='shift'},
    colors={run={'search_colors','search_colors_online'}},
    splitbuf={run={'open','split','vsplit'},conf=true},
    dapnvim={run='start'},
    dff={run='file_expl',conf=true},
    layout={run={'save','load'},conf=true},
    trans={run='cword',conf=true},
    tree_lua_block_split_join={run=true,index='nodes'},
    winpick={run='pick',conf=true},
    textobj={run={'wordcolumn','charcolumn','wordrow','charrow'},keys=function (m,fn)
        fn.map('x','im',m.wordcolumn,{expr=true})
        fn.map('o','im',m.charcolumn,{expr=true})
        fn.map('x','ik',m.wordrow,{expr=true})
        fn.map('o','ik',m.charrow,{expr=true})
    end},
    exchange={run={'ex_oper','ex_eol','ex_line','ex_cancel','ex_visual'},keys=function (m,fn)
        fn.map('n','cx',m.ex_oper)
        fn.map('n','cX',m.ex_eol)
        fn.map('n','cxx',m.ex_line)
        fn.map('n','cxc',m.ex_cancel)
        fn.map('x','X',m.ex_visual)
    end},
    fastmultif={run={'find','rfind'},keys=function (m,fn)
        fn.map('n','f',m.find)
        fn.map('n','F',m.rfind)
    end,conf=true},
    float={run={'move_floating_window','deinitilize','resize_floating_window','make_floating'},keys=function (m,fn)
        fn.map('n','<C-LeftMouse>','')
        fn.map('n','<C-RightMouse>','')
        fn.map('n','<C-LeftDrag>',m.move_floating_window)
        fn.map('n','<C-LeftRelease>',m.deinitilize)
        fn.map('n','<C-RightDrag>',m.resize_floating_window)
        fn.map('n','<C-RightRelease>',m.deinitilize)
    end,conf=true},
    builder={run={'eval','termbuild','swap','set'},conf=true,keys=function (m,fn)
        fn.map('n','<F5>',m.termbuild)
        fn.map('n','<F6>',m.eval)
    end},
    help_cword={run=true,keys=function (m,fn)
        fn.map('n','K',m.run)
    end},
    macro={run={'toggle_rec','play_rec','edit_rec'},keys=function (m,fn)
        fn.map('n','q',m.toggle_rec)
        fn.map('n','Q',m.play_rec)
        fn.map('x','Q',m.play_rec)
        fn.map('n','cq',m.edit_rec)
    end},
    nodeswap={run={'swap_next','swap_prev'},keys=function (m,fn)
        fn.map('n','>a',m.swap_next)
        fn.map('n','<a',m.swap_prev)
    end,conf=true},
    onelinecomment={run=true,keys=function (m,fn)
        fn.map('n','gc',m.run)
        fn.map('x','gc',m.run)
    end},
    unimpaired={run={'edit_prev_file','edit_next_file','get_next_file','set_opt'},keys=function (m,fn)
        fn.map('n','yo',m.set_opt)
        fn.map('n',']f',m.edit_next_file)
        fn.map('n','[f',m.edit_prev_file)
    end},
    whint={run=true,keys=function (m,fn)
        fn.map('i',':',m.run,{expr=true})
    end}
}
function M._require(name)
    return require('small.'..name)
end
function M.to_table(t)
    if type(t)=='string' then return {t} else return t end
end
function M.get_functions(v)
    local funcs={}
    if v.run then vim.list_extend(funcs,M.to_table(v.run==true and 'run' or v.run)) end
    if v.setup then vim.list_extend(funcs,{v.setup==true and 'setup' or v.setup}) end
    assert(#funcs>0,'no functions defined')
    return funcs
end
function M.check(all)
    local function asnot(v,message,...)
        if not v then
            vim.notify(message:format(...),vim.log.levels.ERROR)
            return true
        end
    end
    local plugins={}
    vim.list_extend(plugins,vim.api.nvim_get_runtime_file('lua/small/*',true))
    for _,v in ipairs(plugins) do
        if asnot(M.def[vim.fn.fnamemodify(v,':t:r')],'Plugin `%s` not defined',vim.fn.fnamemodify(v,':t:r')) then
            break
        end
    end
    if not all then return end
    for k,v in pairs(M.def) do
        if v.special or v.color then goto continue end
        local p=M._require(k)
        for _,f in ipairs(M.get_functions(v)) do
            asnot(p[f],'function not defined: `%s` in `%s`',k,f)
        end
        asnot(not p.conf or v.conf,'`conf` not set for `%s`',k)
        asnot(not v.conf or p.conf,'`conf` set for `%s` but should not be set',k)
        asnot(not v.setup or v.event~=nil,'lazy loading not set `%s`',k)
        ::continue::
    end
end
function M.load(name,recursive)
    if not M.def[name] then return end
    if M.loaded[name] and recursive then return end
    if M.loaded[name] then return M._require(name) end
    M.loaded[name]=true
    local plugin=M._require(name)
    local def=M.def[name]
    local conf=M.conf[name] or {setup=false,keys=false}
    if conf.conf then
        assert(def.conf)
        plugin.conf=conf.conf
    end
    if conf.setup~=false and def.setup then
        plugin[def.setup==true and 'setup' or def.setup]()
    end
    if conf.keys~=false and (def.keys or conf.keys) then
        (def.keys or conf.keys)(plugin,{map=function (mode,lhs,callback,opts)
            opts=opts or {}
            vim.api.nvim_set_keymap(mode,lhs,'',{callback=callback,expr=opts.expr,noremap=true,replace_keycodes=opts.expr})
        end})
    end
    return plugin
end
function M.init_package_loader()
    local loaders=package.loaders
    for k,f in ipairs(loaders) do
        if ({debug.getupvalue(f,1)})[2]=='_SMALL_LOADER_' then
            table.remove(loaders,k)
            break
        end
    end
    local upvalue='_SMALL_LOADER_'
    table.insert(loaders,1,function (name)
        _=upvalue
        if name:sub(1,6)=='small.' then
            local p=M.load(name:sub(7),true)
            package.loaded[name]=p
            return p
        end
    end)
    assert(({debug.getupvalue(loaders[1],1)})[2]=='_SMALL_LOADER_')
end
function M.init_keys()
    for name,conf in pairs(M.conf) do
        local def=M.def[name]
        if conf.keys~=false and (def.keys or conf.keys) then
            (def.keys or conf.keys)(setmetatable({},{__index=function (_,fn)
                return function (...)
                    return M.load(name)[fn](...)
                end

            end}),{map=function (mode,lhs,callback,opts)
                    opts=opts or {}
                    vim.api.nvim_set_keymap(mode,lhs,'',{callback=callback,expr=opts.expr,noremap=true,replace_keycodes=opts.expr})
                end})
        end
    end
end
function M.create_autocmd(event,name)
    local pattern
    if event=='~VisualEnter' then
        pattern='*:[vV\x16]'
        event='ModeChanged'
    elseif event=='~Now' or event=='~Fold' then
        M.load(name) return
    elseif event=='~Later' then
        vim.defer_fn(function ()
            M.load(name)
        end,500) return
    elseif event=='~OnKey' then
        M.load(name) return
    elseif event:sub(1,1)=='~' then
        error''
    end
    local done
    vim.api.nvim_create_autocmd(event,{callback=function (data)
        if done then return end
        done=true
        M.load(name)
        if event=='ModeChanged' then
            pattern=data.match
        end
        vim.api.nvim_exec_autocmds(event,{
            data=data,
            pattern=pattern,
        })
    end,once=true,pattern=pattern})
end
function M.init_autocmds()
    for name,conf in pairs(M.conf) do
        local def=M.def[name]
        if not def.event then goto continue end
        if conf.setup==false then goto continue end
        for _,event in ipairs(def.event) do
            M.create_autocmd(event,name)
        end
        ::continue::
    end
end
function M.run(plugins)
    vim.defer_fn(M.check,1000)
    for _,pluginconf in ipairs(vim.tbl_map(M.to_table,plugins)) do
        local name=pluginconf[1]
        assert(M.def[name])
        M.conf[name]=pluginconf
    end
    M.init_autocmds()
    M.init_keys()
    M.init_package_loader()
end
return M
