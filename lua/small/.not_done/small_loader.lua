local M={}
M.def={
    fork={special=true},
    lib={special=true},

    own={setup=true},
    color_cmdline={setup=true},
    cursor_xray={setup=true},
    elastic_tabstop={setup=true},
    foldtext={setup=true,conf=true},
    help_readme={setup=true,build='generate',conf=true},
    highlight_selected={setup=true},
    labull={setup=true},
    specfile={setup=true,conf=true},
    statusbuf={setup=true},
    tabline={setup=true},
    treewarn={setup=true,conf=true},
    typo={setup=true},
    winvis={setup=true},
    zenall={setup=true},
    large={setup='start'},
    beacon={setup='create_autocmd',conf=true},
    debugger={setup='override_error'},

    matchall={setup=true,run='toggle'},
    cursor={setup=true,run={'create_cursor','goto_next_cursor','clear_cursor'},conf=true},
    kitty={setup=true,run={'set_font_size','get_font_size','set_padding','toggle_padding'},conf=true},
    reminder={setup=true,run='sidebar',conf=true},
    notify={setup='override_notify',run={'notify','open_history','dismiss'},conf=true},
    splitbuf={run={'open','split','vsplit'},conf=true},
    copyring={setup=true,run={'put','cycle'},keys=function (m,fn)
        fn.map('n','p',function () m.put(true) end)
        fn.map('n','P',function () m.put(false) end)
        fn.map('n','<A-p>',function () m.cycle(false) end)
        fn.map('n','<A-P>',function () m.cycle(true) end)
    end},

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
        fn.map('i','<F5>',m.termbuild)
        fn.map('i','<F6>',m.eval)
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
        fn.map('n','gc',m.comment_lines)
        fn.map('x','gc',m.comment_lines)
    end},
    unimpaired={run={'edit_prev_file','edit_next_file','get_next_file','set_opt'},keys=function (m,fn)
        fn.map('n','yo',m.set_opt)
        fn.map('n',']f',m.edit_next_file)
        fn.map('n','[f',m.edit_prev_file)
    end},
    whint={run=true,keys=function (m,fn)
        fn.map('i',m.run,{expr=true})
    end}
}
function M.load(plugin)
    vim.dev=nil
    return require('small.'..plugin)
end
function M.to_table(t)
    if type(t)=='string' then return {t} else return t end
end
function M.get_functions(v)
    local funcs={}
    if v.run then vim.list_extend(funcs,M.to_table(v.run==true and 'run' or v.run)) end
    if v.setup then vim.list_extend(funcs,M.to_table(v.setup==true and 'setup' or v.setup)) end
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
        local p=M.load(k)
        for _,f in ipairs(M.get_functions(v)) do
            asnot(p[f],'function not defined: `%s` in `%s`',k,f)
        end
        asnot(not p.conf or v.conf,'`conf` not set for `%s`',k)
        asnot(not v.conf or p.conf,'`conf` set for `%s` but should not be set',k)
        --asnot(v.lazy,'lazy loading not set `%s`',k) --TODO
        ::continue::
    end
end
function M.setup()
    if _G.UA_DEV then
        vim.defer_fn(M.check,1000)
    end
end
if vim.dev then
    M.check(true)
end
return M
