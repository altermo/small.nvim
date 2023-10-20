local has_telescope,_=pcall(require,'telescope')

local M={}
function M.telescope_select(items,opt,on_confirm)
    local pickers=require'telescope.pickers'
    local finders=require'telescope.finders'
    local actions=require'telescope.actions'
    local action_state=require'telescope.actions.state'

    pickers.new({},{
        finder=finders.new_table(items),
        attach_mappings=function(_,map)
            actions.select_default:replace(function()
                local selection=action_state.get_selected_entry()
                on_confirm(selection)
            end)
            return true
        end
    }):find()

end
function M.select(items,opt,on_confirm)
    if has_telescope then
        return M.telescope_select(items,opt,on_confirm)
    end
end
if vim.dev then
    M.select({'1','2','3'},{},vim.pprint)
end
return M
