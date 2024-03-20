local M={conf={interval=150,count=2,color='LawnGreen',minimal=10}}
function M.flash()
    vim.api.nvim_set_hl(0,'SmallBeaconHl',{bg=vim.startswith(M.conf.color,'#') and M.conf.color or vim.api.nvim_get_color_by_name(M.conf.color)})
    if M.conf.count==0 then return end
    local current=vim.fn.matchadd('SmallBeaconHl','.*\\%#.*')
    M.current=current
    local id=current
    local winid=vim.api.nvim_get_current_win()
    local count=M.conf.count-1
    local function flash()
        vim.fn.matchdelete(id,winid)
        count=count-1
        if count<0 or M.current~=current then return end
        vim.defer_fn(function ()
            id=vim.fn.matchadd('SmallBeaconHl','.*\\%#.*')
            winid=vim.api.nvim_get_current_win()
            vim.defer_fn(flash,M.conf.interval)
        end,M.conf.interval)
    end
    vim.defer_fn(flash,M.conf.interval)
end
---@return number
function M.create_autocmd()
    local last_pos=vim.api.nvim_win_get_cursor(0)
    local last_win=vim.api.nvim_get_current_win()
    return vim.api.nvim_create_autocmd({'CursorMoved','CursorMovedI'},{callback=function ()
        local pos=vim.api.nvim_win_get_cursor(0)
        local win=vim.api.nvim_get_current_win()
        if win~=last_win
        or math.abs(last_pos[1]-pos[1])>M.conf.minimal then M.flash() end
        last_pos=pos
        last_win=win
    end,group=vim.api.nvim_create_augroup('small.beacon',{})})
end
if vim.dev then
    M.create_autocmd()
end
return M
