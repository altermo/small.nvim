local M={save=nil,I={}}
function M.I.to_lsp_range(reg)
    local start_line=math.min(unpack(vim.tbl_keys(reg)))
    local end_line=math.max(unpack(vim.tbl_keys(reg)))
    local start_col=reg[start_line][1]
    local end_col=reg[end_line][2]
    if end_col=='-1' then end_col=#vim.api.nvim_buf_get_lines(0,end_line+1,end_line,false)[1] end
    return {start={line=start_line,character=start_col},['end']={line=end_line,character=end_col}}
end
M.I.get_range=function(reg)
    local r=M.I.to_lsp_range(reg)
    local lines=vim.api.nvim_buf_get_lines(0,r.start.line,r['end'].line+1,false)
    --TODO: use `nvim_buf_get_text` instead
    if r.start.line==r['end'].line then
        lines[1]=lines[1]:sub(r.start.character+1,r['end'].character)
    else
        lines[1]=lines[1]:sub(r.start.character+1)
        lines[#lines]=lines[#lines]:sub(1,r['end'].character)
    end
    return table.concat(lines,'\n')
end
function M.ex_range(start,fin)
    if not M.save then
        local ns=vim.api.nvim_create_namespace('exchange')
        vim.highlight.range(0,ns,'CurSearch',start,fin,{inclusive=true})
        M.save=vim.region(0,start,fin,'',true)
        return
    end
    local reg=vim.region(0,start,fin,'',true)
    local edit1={range=M.I.to_lsp_range(reg),newText=M.I.get_range(M.save)}
    local edit2={range=M.I.to_lsp_range(M.save),newText=M.I.get_range(reg)}
    vim.lsp.util.apply_text_edits({edit1,edit2},0,'urt-8')
    M.ex_cancel()
end
function M.ex_line()
    local line=unpack(vim.api.nvim_win_get_cursor(0))-1
    M.ex_range({line,0},{line,#vim.api.nvim_get_current_line()})
end
function M.ex_visual()
    if vim.fn.mode()~='V' then
        M.ex_range('.','v')
    else
        local fin,start=vim.fn.line'v'-1,vim.fn.line'.'-1
        if start>fin then
            M.ex_range({fin,0},{start,#vim.api.nvim_get_current_line()})
        else
            M.ex_range({start,0},{fin,#vim.api.nvim_buf_get_lines(0,fin,fin+1,false)[1]})
        end
    end
    vim.api.nvim_input('<esc>')
end
function M.ex_oper()
    _G.ExOperFunc=function ()
        _G.ExOperFunc=nil
        M.ex_range("'[","']")
    end
    vim.o.operatorfunc='v:lua.ExOperFunc'
    vim.api.nvim_feedkeys(vim.v.count1..'g@','mi',false)
end
function M.ex_eol()
    local line=unpack(vim.api.nvim_win_get_cursor(0))-1
    M.ex_range({line,vim.fn.col'.'-1},{line,#vim.api.nvim_get_current_line()})
end
function M.ex_cancel()
    local ns=vim.api.nvim_create_namespace('exchange')
    vim.api.nvim_buf_clear_namespace(0,ns,0,-1)
    M.save=nil
end
if vim.dev then
    local ns=vim.api.nvim_create_namespace('exchange')
    vim.api.nvim_buf_clear_namespace(0,ns,0,-1)
    vim.keymap.set('n','cx',M.ex_oper)
    vim.keymap.set('n','cX',M.ex_eol)
    vim.keymap.set('n','cxx',M.ex_line)
    vim.keymap.set('n','cxc',M.ex_cancel)
    vim.keymap.set('x','X',M.ex_visual)
end
return M
