local M={}
function M.clear_word() pcall(vim.fn.matchdelete,M.save.matchid,M.save.window) end
function M.clear_lsp() vim.api.nvim_win_call(M.save.window,vim.lsp.buf.clear_references) end
function M.clear()
    if not M.save then return end
    pcall(M.clear_word)
    pcall(M.clear_lsp)
    M.save=nil
end
function M.highlight_word()
    local line=vim.api.nvim_get_current_line()
    local s,match=pcall(vim.fn.matchadd,'Underline','\\M\\<'..line:sub(M.save.beg+1,M.save.fin):gsub([[\]],[[\\]])..'\\>',-1)
    if s then M.save.matchid=match end
end
function M.highlight_lsp()
    for _,v in ipairs(vim.lsp.get_clients({bufnr=0})) do
        if not v.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then return end
    end
    vim.lsp.buf.document_highlight()
end
function M.check_is_word()
    local col=vim.fn.col('.') --[[@as number]]
    local line=vim.api.nvim_get_current_line()
    return vim.regex('\\k'):match_str(line:sub(col,col))
end
function M.set_save()
    local linenr,col=unpack(vim.api.nvim_win_get_cursor(0))
    local line=vim.api.nvim_get_current_line()
    M.save={
        window=vim.api.nvim_get_current_win(),
        fin=(vim.regex('[^[:keyword:]]'):match_str(line:sub(col+1)) or #line-col)+col,
        beg=col+1-(vim.regex('[^[:keyword:]]'):match_str(line:sub(1,col+1):reverse()) or col+1),
        linenr=linenr}
end
function M.is_still_on_word()
    if not M.save then return end
    local linenr,col=unpack(vim.api.nvim_win_get_cursor(0))
    return col>=M.save.beg and col<M.save.fin and linenr==M.save.linenr
end
function M.highlight()
    if M.is_still_on_word() then return end
    M.clear()
    if not M.check_is_word() then return end
    if M.disable then return end
    M.set_save()
    M.highlight_lsp()
    M.highlight_word()
end
function M.redraw()
    M.clear()
    M.highlight()
end
function M.setup()
    vim.api.nvim_create_augroup('matchall',{})
    vim.api.nvim_create_autocmd({'InsertEnter','TermEnter','WinLeave','CmdlineEnter'},{group='matchall',callback=M.clear})
    vim.api.nvim_create_autocmd({'CursorMoved'},{group='matchall',callback=M.highlight})
    vim.api.nvim_create_autocmd({'TextChanged','CmdLineLeave'},{group='matchall',callback=M.redraw})
    vim.api.nvim_create_user_command('ToggleMatchAll',function () M.disable=not M.disable end,{})
    M.highlight()
end
return M
