local M={conf={handle=function(x)
    if type(x)=='string' then
        vim.notify(x)
    else
        vim.notify(vim.inspect(x))
    end
end}}
function M.setup()
    local sys
    vim.api.nvim_create_autocmd({'CursorMoved','CursorMovedI'},{
        group=vim.api.nvim_create_augroup('small_node_eval',{}),
        callback=function()
            if M.conf.handle_pre then M.conf.handle_pre() end
            if not pcall(vim.treesitter.get_parser) then return end
            if sys then sys:kill() end
            local node=vim.treesitter.get_node({ignore_injections=false})
            while node do
                if node:type()==M.conf.node then
                    break
                end
                node=node:parent()
            end
            if not node then return end
            local text=vim.treesitter.get_node_text(node,0)
            text=text:sub(2,-2)
            sys=vim.system({M.conf.bin,text},{},function (out)
                local res=out.stdout:sub(1,-2)
                M.conf.handle(res)
            end)

        end
    })
end
return M
