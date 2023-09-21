---@class dff.config
---@field wintype 'current'|'split'|'vsplit'--|function|'float'
---@field wjust number
---@field hjust number
---@field ending string
local default_conf={
    wintype='current',
    wjust=10,
    hjust=3,
    ending='\n',
}

local file_expl=require'small.dff.file_expl'
local M={conf=default_conf}
function M.file_expl(file)
    file_expl.open(file)
end
return M
