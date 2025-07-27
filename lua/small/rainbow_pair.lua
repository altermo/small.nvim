local M={conf={pairs={
    '(_ "(" @s ")" @e) @a',
    '(_ "{" @s "}" @e) @a',
    '(_ "[" @s "]" @e) @a',
},hl={
        --- Values taken from https://gitlab.com/HiPhish/rainbow-delimiters.nvim
        {fg='#cc241d',ctermfg='Red'},
        {fg='#d79921',ctermfg='Yellow'},
        {fg='#458588',ctermfg='Blue'},
        {fg='#d65d0e',ctermfg='White'},
        {fg='#689d6a',ctermfg='Green'},
        {fg='#b16286',ctermfg='Magenta'},
        {fg='#a89984',ctermfg='Cyan'},
    }},ns=vim.api.nvim_create_namespace('small_rainbow_pair')}

local function highlight_range(bufnr,range,level)
    local rows,cols,_,rowe,cole=unpack(range)
    pcall(function ()
        vim.api.nvim_buf_set_extmark(bufnr,M.ns,rows,cols,{
            end_line=rowe,end_col=cole,
            hl_group=('rainbow'..((level)%(#M.conf.hl)+1)),
        })
    end)
end
local _cache={}
local function update_highlighting(bufnr)
    local lang=vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
    if not lang then return end
    local parser=vim.treesitter.get_parser(bufnr,lang,{error=false})
    if not parser then return end
    if not _cache[lang] then
        local queries={}
        for _,v in ipairs(M.conf.pairs) do
            if pcall(vim.treesitter.query.parse,lang,v) then
                table.insert(queries,v)
            end
        end
        _cache[lang]=table.concat(queries,'\n')
    end
    parser:parse(nil,function (err,trees)
        if err or not trees then return end
        local query=vim.treesitter.query.parse(lang,_cache[lang])
        assert(#query.captures==3)
        local reveser_matches={}
        for _,tree in ipairs(trees) do
            for _,match in query:iter_matches(tree:root(),bufnr) do
                assert(query.captures[1]=='s' and #match[1]==1)
                assert(query.captures[2]=='e' and #match[2]==1)
                assert(query.captures[3]=='a' and #match[3]==1)
                table.insert(reveser_matches,1,match)
            end
        end
        local level=0
        vim.api.nvim_buf_clear_namespace(bufnr,M.ns,0,-1)
        local stack={math.huge}
        for _,match in ipairs(reveser_matches) do
            local node_a=match[3][1]
            local byte=vim.treesitter.get_range(node_a,bufnr)[3]
            if byte>=stack[#stack] then
                level=level+1
                table.insert(stack,byte)
            else
                while #stack>0 and byte<stack[#stack] do
                    table.remove(stack)
                    level=level-1
                end
                level=level+1
                table.insert(stack,byte)
            end
            local node_s=match[1][1]
            highlight_range(bufnr,vim.treesitter.get_range(node_s,bufnr),level)
            local node_e=match[2][1]
            highlight_range(bufnr,vim.treesitter.get_range(node_e,bufnr),level)
        end
    end)
end
function M.setup()
    for k,v in ipairs(M.conf.hl) do
        vim.api.nvim_set_hl(0,'rainbow'..k,v)
    end
    vim.api.nvim_create_autocmd({'TextChanged','TextChangedI','TextChangedP','BufRead'},{callback=function (ev)
        update_highlighting(ev.buf)
    end,group=vim.api.nvim_create_augroup('small_rainbow_pair',{clear=true})})
end

return M
