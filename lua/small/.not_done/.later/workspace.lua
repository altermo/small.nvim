local M={}
local datajson=vim.fn.stdpath('state')..'/workspace.json'
local default_data_json={
    current_workspace=0,
    workspaces={
        [0]={}
    }
}
function M.get_json()
    if vim.fn.exists(datajson) then
        return vim.json.read(datajson)
    else
        return default_data_json
    end
end
function M.get_workspaces()
    local json=M.get_json()
    return json.workspaces
end
function M.setup()
    vim.api.nvim_create_autocmd(
        'VimEnter',
        {callback=function ()
            if vim.fn.argc()==0 then
                vim.fn.edit('.bashrc')
            end
        end}
    )
end
return M
