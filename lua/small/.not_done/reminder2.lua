local M={conf={},ns=vim.api.nvim_create_namespace('small.reminder2')}
function M.parse_file(file)
    local items={}
    for line in io.lines(file) do
        local doc=line:match('^%s*[+-]%s*(.*)$')
        if doc then
            local item={}
            doc:gsub('[^a-zA-Z0-9_-]@([a-zA-Z0-9_-])+',function (tag)
                if tag:match('^%d%d%d%d%-%d%d%-%d%d$') then
                    item.date=tag
                elseif tag:match('^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d$') then
                    item.date=tag
                end
            end)
            if item.date then
                table.insert(items,item)
            end
        end
    end
    return items
end
function M.update()
    --TODO
end
function M.notify_today()
    --TODO
end
function M.draw(buf)
    --TODO
    --FIX: when hour and min are set, use time to that day rather than time to that min (so if time is 10:00 and date is set to next day 11:00 then the differenc will be 2 days rather than 1)
end
function M.setup()
    assert(M.conf.path,'conf: small.reminder2.conf.path is not set')
    vim.fn.timer_start(30000,vim.schedule_wrap(M.update),{['repeat']=-1})
    vim.defer_fn(M.notify_today,1000)
end
