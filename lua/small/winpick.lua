local M={conf={color='DarkGreen',symbols={'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'}}}
---@return number?
function M.pick()
    vim.api.nvim_set_hl(0,'SmallWinpickHl',{bg=vim.startswith(M.conf.color,'#') and M.conf.color or vim.api.nvim_get_color_by_name(M.conf.color)})
    local map={}
    local wins=vim.api.nvim_tabpage_list_wins(0)
    local count=0
    for _,v in ipairs(wins) do
        if v==vim.api.nvim_get_current_win() then goto continue end
        if vim.api.nvim_win_get_config(v).relative~='' then goto continue end
        count=count+1
        map[M.conf.symbols[count]]={win=v}
        ::continue::
    end
    for k,v in pairs(map) do
        v.winbar=vim.wo[v.win].winbar
        vim.wo[v.win].winbar='%#SmallWinpickHl#'..(' '):rep(vim.api.nvim_win_get_width(v.win)/2)..k
    end
    local char
    if vim.tbl_isempty(map) then
    elseif vim.tbl_count(map)==1 then char=next(map)
    else
        vim.cmd.mod()
        _,char=pcall(vim.fn.getcharstr)
    end
    for _,v in pairs(map) do
        vim.wo[v.win].winbar=v.winbar
    end
    if map[char] then return map[char].win end
end
if vim.dev then
    print(M.pick())
end
return M
