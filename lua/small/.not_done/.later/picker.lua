--[[
--as a replacement for vim.ui.select and nvim-telescope/telescope-ui-select.nvim
--]]
local has_telescope,_=pcall(require,'telescope')

local M={}
function M.telescope_select(items,opt,on_confirm,preview)
    local pickers=require'telescope.pickers'
    local finders=require'telescope.finders'
    local actions=require'telescope.actions'
    local previewer=require'telescope.previewers'
    local action_state=require'telescope.actions.state'

    pickers.new(opt,{
        finder=finders.new_table(items),
        previewer=preview and previewer.new_buffer_previewer{define_preview=function (self,entry)
            vim.api.nvim_buf_set_lines(self.state.bufnr,0,-1,false,preview(entry) or {})
        end},
        attach_mappings=function(buf,map)
            actions.select_default:replace(function()
                local selection=action_state.get_selected_entry()
                on_confirm(selection)
                on_confirm=function() end
                actions.close(buf)
            end)
            actions.close:enhance({post=function ()
                on_confirm(nil)
            end})
            return true
        end
    }):find()

end
function M.select(items,opt,on_confirm,preview)
    if has_telescope then
        return M.telescope_select(items,opt,on_confirm,preview)
    end
end
if vim.dev then
    M.select({'a','b','c'},{},vim.pprint,function (i) return {i[1]} end)
end
return M
