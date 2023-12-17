--[[
--as a replacement for vim.ui.select and nvim-telescope/telescope-ui-select.nvim
--]]
local M={}

M.preview={
}
function M.telescope_select(items,config,on_confirm,opts)
    local pickers=require'telescope.pickers'
    local finders=require'telescope.finders'
    local actions=require'telescope.actions'
    local previewer=require'telescope.previewers'
    local action_state=require'telescope.actions.state'
    local conf=require'telescope.config'.values
    on_confirm=vim.schedule_wrap(on_confirm)

    pickers.new(opts,{
        finder=finders.new_table(items),
        previewer=config.preview and previewer.new_buffer_previewer{define_preview=function (self,entry)
            vim.api.nvim_buf_set_lines(self.state.bufnr,0,-1,false,config.preview(entry,self) or {})
        end},
        attach_mappings=function(buf)
            actions.select_default:replace(function()
                local selection=action_state.get_selected_entry()
                on_confirm(selection[1],selection.index)
                on_confirm=function() end
                actions.close(buf)
            end)
            actions.close:enhance({post=function () on_confirm() end})
            return true
        end,
        sorter = conf.generic_sorter(opts),
    }):find()

end
function M.select(items,conf,on_confirm)
    if type(conf.preview)=='string' then
        conf.preview=M.preview[conf.preview]
    end
    if pcall(require,'telescope') then
        return M.telescope_select(items,conf,on_confirm,{})
    else
        vim.ui.select(items,conf,on_confirm)
    end
end
if vim.dev then
    M.select({'a','b','c'},{preview=function (i) return {i[1]} end},vim.pprint)
end
function M.fn(...)
    M.select(...)
end
return M.fn,M
