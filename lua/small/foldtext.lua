local M={conf={treesitter=false,skip_fn_luadoc=false}}
do
    --NOTE: The following code has been copied from neovim
    --It was removed in commit https://github.com/neovim/neovim/commit/0892c08
    local api=vim.api
    local ts=vim.treesitter
    ---START of copied code {{
    function M.vim_treesitter_foldtext()
        local foldstart = vim.v.foldstart
        local bufnr = api.nvim_get_current_buf()

        ---@type boolean, LanguageTree
        local ok, parser = pcall(ts.get_parser, bufnr)
        if not ok then
            return vim.fn.foldtext()
        end

        local query = ts.query.get(parser:lang(), 'highlights')
        if not query then
            return vim.fn.foldtext()
        end

        local tree = parser:parse({ foldstart - 1, foldstart })[1]

        local line = api.nvim_buf_get_lines(bufnr, foldstart - 1, foldstart, false)[1]
        if not line then
            return vim.fn.foldtext()
        end

        ---@type { [1]: string, [2]: string[], range: { [1]: integer, [2]: integer } }[] | { [1]: string, [2]: string[] }[]
        local result = {}

        local line_pos = 0

        for id, node, metadata in query:iter_captures(tree:root(), 0, foldstart - 1, foldstart) do
            local name = query.captures[id]
            local start_row, start_col, end_row, end_col = node:range()

            local priority = tonumber(metadata.priority or vim.highlight.priorities.treesitter)

            if start_row == foldstart - 1 and end_row == foldstart - 1 then
                -- check for characters ignored by treesitter
                if start_col > line_pos then
                    table.insert(result, {
                        line:sub(line_pos + 1, start_col),
                        {},
                        range = { line_pos, start_col },
                    })
                end
                line_pos = end_col

                local text = line:sub(start_col + 1, end_col)
                table.insert(result, { text, { { '@' .. name, priority } }, range = { start_col, end_col } })
            end
        end

        local i = 1
        while i <= #result do
            -- find first capture that is not in current range and apply highlights on the way
            local j = i + 1
            while
                j <= #result
                and result[j].range[1] >= result[i].range[1]
                and result[j].range[2] <= result[i].range[2]
                do
                for k, v in ipairs(result[i][2]) do
                    if not vim.tbl_contains(result[j][2], v) then
                        table.insert(result[j][2], k, v)
                    end
                end
                j = j + 1
            end

            -- remove the parent capture if it is split into children
            if j > i + 1 then
                table.remove(result, i)
            else
                -- highlights need to be sorted by priority, on equal prio, the deeper nested capture (earlier
                -- in list) should be considered higher prio
                if #result[i][2] > 1 then
                    table.sort(result[i][2], function(a, b)
                        return a[2] < b[2]
                    end)
                end

                result[i][2] = vim.tbl_map(function(tbl)
                    return tbl[1]
                end, result[i][2])
                result[i] = { result[i][1], result[i][2] }

                i = i + 1
            end
        end

        return result
    end
    ---}} END of copied code
end
function M.GetTreesitterFoldText(just,fallback)
    local function fall()
        fallback=fallback:sub(just+1)..' '
        local len=#vim.str_utf_pos(fallback)
        return {{fallback}},len+1
    end
    if not M.conf.treesitter then
        return fall()
    end
    local foldtext=M.vim_treesitter_foldtext()
    if type(foldtext)=='string' or vim.tbl_isempty(foldtext) then
        return fall()
    end
    if just~=1 then
        while just>0 do
            just=just-1
            if foldtext[1][1]=='' then
                table.remove(foldtext,1)
            end
            foldtext[1][1]=foldtext[1][1]:sub(2)
        end
    end
    table.insert(foldtext,{' '})
    local len=0
    for _,v in ipairs(foldtext) do
        len=len+#(v[1])
    end
    return foldtext,len
end
function M.MyFoldText()
    local bul='•'
    local ret={}
    if M.conf.skip_fn_luadoc and vim.o.filetype=='lua' then
        local linenr=vim.v.foldstart
        while linenr~=vim.v.foldend do
            local line=vim.fn.getline(linenr)
            if not line:match('^%-%-%-*') then break end
            linenr=linenr+1
        end
        if vim.fn.getline(linenr):find('^[local ]*function') and linenr~=vim.v.foldend then
            vim.v.foldstart=linenr
        end
    end
    local wininfo=vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
    local line=vim.fn.getline(vim.v.foldstart)
    local ident=line:match('^[%s-]*')
    local indent=#ident>0 and bul:rep(#ident-1)..' ' or ''
    table.insert(ret,{indent})
    local left,leftlen=M.GetTreesitterFoldText(#ident,line)
    vim.list_extend(ret,left)
    local percent=(vim.v.foldend-vim.v.foldstart+1)/vim.api.nvim_buf_line_count(0)*100
    local right=string.format(
        ' %d lines:%3s%% %s',
        vim.v.foldend-vim.v.foldstart+1,
        percent<1 and tostring(percent):sub(2,3) or math.floor(percent),
        bul:rep(3))
    local len=#vim.str_utf_pos(indent)+leftlen+wininfo.textoff+#vim.str_utf_pos(right)
    local middle=bul:rep(wininfo.width-len)
    table.insert(ret,{middle})
    table.insert(ret,{right})
    return ret
end
function M.setup()
    _G.MyFoldText=M.MyFoldText
    vim.o['foldtext']='v:lua.MyFoldText()'
end
return M
