local M={}
function M.telescope(items,opts,on_choice)
    local pickers=require'telescope.pickers'
    local finders=require'telescope.finders'
    local actions=require'telescope.actions'
    local action_state=require'telescope.actions.state'
    local conf=require('telescope.config').values
    local has_selected=false
    local pick=pickers.new({},{
        finder=finders.new_table{
            results=items,
            entry_maker=function (e)
                return {
                    value=e,
                    display=(opts.format_item or tostring)(e),
                    ordinal=(opts.format_item or tostring)(e),
                }
            end,
        },
        attach_mappings=function(bufnr)
            actions.select_default:replace(function()
                local select=action_state.get_selected_entry()
                actions.close(bufnr)
                has_selected=true
                if not select then
                    on_choice()
                else
                    on_choice(select.value,select.index)
                end
            end)

            return true

        end,
        sorter = conf.generic_sorter(),
    })
    if opts.preview then
        local fn=pick.set_selection
        pick.set_selection=function(...)
            fn(...)
            local e=pick:get_selection()
            if not e then opts.preview() return end
            opts.preview(e.value,e.index)
        end
    end
    if opts.cancel then
        local fn=pick.close_windows
        pick.close_windows=function(...)
            fn(...)
            if has_selected then return end
            opts.cancel()
        end
    end
    pick:find()
end

function M.fn(...)
    if pcall(require,'fzf-lua') then
        require'fzf-lua.providers.ui_select'.ui_select(...)
    elseif pcall(require,'telescope') then
        M.telescope(...)
    else
        vim.ui.select(...)
    end
end
return M.fn,M
