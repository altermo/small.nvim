local M={conf={},ns=vim.api.nvim_create_namespace('small.reminder')}
function M.parse_date(date)
    local reg='(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d)'
    if not date:match(reg) then date=date..' 00:00' end
    local year,month,day,hour,minute=date:match(reg)
    return {year=year,month=month,day=day,hour=hour,min=minute}
end
function M.get_times()
    local times={}
    local reg1=[[^%s*[-+] %[ %]%s*(.*)%s%(@(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d)%)]]
    local reg2=[[^%s*[-+] %[ %]%s*(.*)%s%(@(%d%d%d%d%-%d%d%-%d%d)%)]]
    local row=1
    for i in io.lines(M.conf.path) do
        for _,reg in ipairs{reg1,reg2} do
            local doc,date=i:match(reg)
            if doc then table.insert(times,{doc,M.parse_date(date),date,row}) end
        end
        row=row+1
    end
    table.sort(times,function(a,b) return os.time(a[2])<os.time(b[2]) end)
    return times
end
function M.next_day()
    local t=os.date('*t',os.time()+86400)
    t.hour=0
    t.min=0
    t.sec=0
    ---@diagnostic disable-next-line: param-type-mismatch
    return os.time(t)
end
function M.notify_timed()
    local times=M.get_times()
    for _,v in ipairs(times) do
        if #v[3]==16 and os.time()>os.time(v[2]) then
            ---@diagnostic disable-next-line: redundant-parameter
            vim.notify(v[1]..' '..v[3])
        end
    end
end
function M.notify_today()
    local times=M.get_times()
    for _,v in ipairs(times) do
        if os.time()>os.time(v[2]) then
            ---@diagnostic disable-next-line: redundant-parameter
            vim.notify(v[1]..' '..v[3]..(' '):rep(16-#v[3]))
        elseif M.next_day()>os.time(v[2]) then
            ---@diagnostic disable-next-line: redundant-parameter
            vim.notify(v[1]..' '..v[3],vim.log.levels.TRACE)
        end
    end
end
function M.draw(buf)
    vim.api.nvim_buf_clear_namespace(buf,M.ns,0,-1)
    local times=M.get_times()
    for _,v in ipairs(times) do
        local text=''
        local hl
        if (os.time()>os.time(v[2]) and #v[3]==16) or ((M.next_day()-86400)>os.time(v[2])) then
            hl='Error'
            text='OVERDUE'
        elseif #v[3]==16 and M.next_day()>os.time(v[2]) then --TODO: test later
            hl='Character'
            local t=os.date('*t')
            local min=v[2].min-t.min
            local h=v[2].hour-t.hour
            if min<0 then min=60+min h=h-1 end
            text='in '..h..'h '..min..'m'
        elseif M.next_day()>os.time(v[2]) then
            hl='Character'
            text='TODAY'
        else
            hl='String'
            local t=os.time(v[2])-os.time()+86400
            if t>=31556926 then
                text=text..math.floor(t/31556926)..'y '
                t=t%31556926
            end
            if t>=2629743 then
                text=text..math.floor(t/2629743)..'m '
                t=t%2629743
            end
            if t>=604800 then
                text=text..math.floor(t/604800)..'w '
                t=t%604800
            end
            if t>=86400 then
                text=text..math.floor(t/86400)..'d '
                t=t%86400
            end
        end
        vim.api.nvim_buf_set_extmark(buf,M.ns,v[4]-1,0,{virt_text={{'due: ','Comment'},{text,hl}}})
    end
end
function M.setup()
    if not M.conf.path then error('conf: small.reminder.conf.path is not set') end
    vim.fn.timer_start(30000,vim.schedule_wrap(M.notify_timed),{['repeat']=-1})
    vim.defer_fn(M.notify_today,1000)
    vim.api.nvim_create_autocmd('BufRead',{callback=function (ev)
        if ev.file==M.conf.path then
            M.draw(ev.buf)
            vim.api.nvim_create_autocmd('TextChanged',{buffer=ev.buf,callback=function ()
                M.draw(ev.buf)
            end})
        end
    end})
end
function M.sidebar()
    local times=M.get_times()
    local dates=vim.defaulttable()
    for _,v in ipairs(times) do
        table.insert(dates[v[2].year..'-'..v[2].month..'-'..v[2].day],v)
    end
    local lines={}
    for k,v in vim.spairs(dates) do
        table.sort(v,function(a,b) return os.time(a[2])<os.time(b[2]) end)
        table.insert(lines,'')
        table.insert(lines,'#'..k)
        for _,i in ipairs(v) do
            if #i[3]==16 then
                table.insert(lines,i[2].hour..':'..i[2].min..' '..i[1])
            elseif type(i[1])=='string' then
                table.insert(lines,i[1])
            end
        end
    end
    table.remove(lines,1)
    local buf=vim.api.nvim_create_buf(true,true)
    vim.bo[buf].bufhidden='wipe'
    vim.api.nvim_buf_set_lines(buf,0,-1,true,lines)
    vim.cmd.vnew()
    vim.api.nvim_set_current_buf(buf)
end
if vim.dev then
    M.conf.path='/home/user/.gtd/vault/gtd/Plans.md'
    M.sidebar()
end
return M

