local M={}
function M.incahrs(chars)
    local differ=chars:match('%u') and (chars:match('%U') and error('string:'..chars..' may not contain booth upper and lower case') or 65) or 97
    local tbl=vim.iter(chars:reverse():gmatch('.')):map(string.byte):totable()
    tbl[1]=(1+(tbl[1] or differ-1))
    local i=1
    while tbl[i]-differ==26 do
        tbl[i]=tbl[i]-26
        i=i+1
        tbl[i]=(tbl[i] or differ-1)+1
    end
    return vim.iter(tbl):fold("",function (sum,v) return sum..string.char(v) end):reverse()
end
function M.labull(inp)
    return (
        --inp:match('^%s*[+%-]+ [[].[]] ') or
        --inp:match('^%s*[+%-]+ ') or
        inp:match('^%s*[+%-] [[].[]] ') or
        inp:match('^%s*[+%-] ') or
        (inp:match('^%s*%d+%.%a+[.)] ') and inp:gsub('^(%s*%d+%.)(%a+)([.)] ).*',function (indent,number,end_) return indent..M.incahrs(number)..end_ end)) or
        (inp:match('^%s*%d+[.)] ') and inp:gsub('^(%s*)(%d+)([.)] ).*',function (indent,number,end_) return indent..(tonumber(number)+1)..end_ end)) or
        (inp:match('^%s*%a+[.)] ') and inp:gsub('^(%s*)(%a+)([.)] ).*',function (indent,number,end_) return indent..M.incahrs(number)..end_ end)))
        --(vim.o.filetype=='lua' and inp:match('^---(@field )')))
end
function M.run()
    local laline=M.labull(vim.api.nvim_get_current_line())
    return 'o'..(laline and ('<esc>A'..laline) or '')
end
function M.setup()
    vim.on_key(function(key)
        if (key~='o' or vim.api.nvim_get_mode().mode~='n')
            and (key~='\r' or vim.api.nvim_get_mode().mode~='i') then
            return
        end
        local laline=M.labull(vim.api.nvim_get_current_line())
        vim.schedule_wrap(vim.api.nvim_feedkeys)(vim.keycode(laline and ('<esc>I'..laline) or ''),'n',false)
    end,vim.api.nvim_create_namespace'small_labull')
end
return M
