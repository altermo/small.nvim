---@class small.dff.config
---@field ending string
local default_conf={ending='\n', }
local M={conf=default_conf}
---@param path string?
---@param conf small.dff.config?
function M.file_expl(path,conf)
    require'small.dff.file_expl'.open(path,conf)
end
return M
