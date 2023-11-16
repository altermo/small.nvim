local M={conf={}}
function M.parse_date(date)
    local reg='(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d)'
    local year,month,day,hour,minute=date:match(reg)
    return {year=year,month=month,day=day,hour=hour,min=minute}
end
function M.get_times()
    local times={}
    local reg=[[^%s*%- %[ %]%s*(.*)%s%(@(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d)%)]]
    for i in io.lines(M.conf.path) do
        local doc,date=i:match(reg)
        if doc then table.insert(times,{doc,M.parse_date(date)}) end
    end
    return times
end
function M.is_overdo(date)
    local num=os.time(date)
    local t=os.time()
    return t>num
end
function M.fn()
    local times=M.get_times()
    local to_dos={}
    for _,v in ipairs(times) do
        if M.is_overdo(v[2]) then
            table.insert(to_dos,v[1])
        end
    end
    if #to_dos==0 then return end
    local msg='TODO:\n'..table.concat(to_dos,'\n')
    vim.fn.timer_start(3500,function() vim.notify(msg) end,{['repeat']=5})
end
function M.setup()
    if not M.conf.path then
        error('conf: reminder.path is not set')
    end
    vim.fn.timer_start(30000,M.fn,{['repeat']=-1})
    M.fn()
end
return M
