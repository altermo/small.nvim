local M={}
local notimplemented=vim.defaulttable()
function M.get_daemon()
    return notimplemented
end
function M.get_info(d)
end
function M.connect(d)
    M.get_info(d)
    M.setup_sendinfo(d)
end
function M.init()
    ---@diagnostic disable-next-line: undefined-field
    if _G.DONT_DAEMON then return end
    local daemon=M.get_daemon()
    if not daemon then
        return M.init_daemon()
    end
    M.connect(daemon)
end

return M
