local M={conf={warn_soon_todo_before=60*10},ns=vim.api.nvim_create_namespace('small.reminder2')}
function M.parse_date(date)
    local reg='(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d)'
    if not date:match(reg) then date=date..' 00:00' end
    local year,month,day,hour,minute=date:match(reg)
    return {year=year,month=month,day=day,hour=hour,min=minute},{year=year,month=month,day=day}
end
function M.next_day()
    return math.floor(os.time()/86400+1)*86400
end
function M.parse_file_or_buf(file_or_buf)
    local items={}
    local row=0
    for line in type(file_or_buf)=='strint' and io.lines(file_or_buf) or vim.iter(vim.api.nvim_buf_get_lines(file_or_buf,0,-1,false)) do
        row=row+1
        local doc=line:match('^%s*[+-]%s*(.*)$')
        if doc then
            local item={row=row,doc=doc:gsub('[^a-zA-Z0-9_-]@.*$','')}
            doc:gsub('[^a-zA-Z0-9_-]@([a-zA-Z0-9_-]+)',function (tag)
                if tag:match('^%d%d%d%d%-%d%d%-%d%d$') then
                    item.date=M.parse_date(tag)
                elseif tag:match('^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d$') then
                    item.date=M.parse_date(tag)
                    item.time=true
                elseif tag:match('^a%d%d:%d%d$') then
                    item.only_show_after_time=tag:match('^a(%d%d:%d%d)$')
                elseif tag=='r' then
                    item.repeated=true
                elseif tag:match('^p%d+$') then
                    item.amount_days_preparation_needed=tag:match('^p(%d+)$')
                elseif tag=='asap' then
                    item.date=M.parse_date(os.date('%Y-%m-%d %H:%M'))
                else
                    item.error=item.error or {}
                    table.insert(item.error,'WARN: unknown tag: '..tag)
                end
            end)
            if item.date or item.error then
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
    vim.api.nvim_buf_clear_namespace(buf,M.ns,0,-1)
    local items=M.parse_file_or_buf(buf)
    for item in vim.iter(items) do
        local text
        if item.error then
            text={{table.concat(item.error,', '),'ErrorMsg'}}
        elseif item.date and (item.time and os.time()>os.time(item.date)) or ((M.next_day()-86400)>os.time(item.date)) then
            text={{'OVERDUE','Error'}}
        elseif item.date and item.time and M.next_day()>os.time(item.date) then
            local t=os.date('*t')
            local min=item.date.min-t.min
            local h=item.date.hour-t.hour
            if min<0 then min=60+min h=h-1 end
            text='in '..h..'h '..min..'m'
            text={{'due: ','Comment'},{'in '..h..'h '..min..'m','character'}}
        elseif item.date and M.next_day()>os.time(item.date) then
            text={{'due: ','Comment'},{'TODAY','character'}}
        elseif item.date then
            local t=math.floor(os.time(item.date)/86400+1)*86400-os.time()+86400
            local te=''
            if t>=31556926 then
                te=te..math.floor(t/31556926)..'y '
                t=t%31556926
            end
            if t>=2629743 then
                te=te..math.floor(t/2629743)..'m '
                t=t%2629743
            end
            if t>=604800 then
                te=te..math.floor(t/604800)..'w '
                t=t%604800
            end
            if t>=86400 then
                te=te..math.floor(t/86400)..'d '
                t=t%86400
            end
            text={{'due: ','Comment'},{te,'String'}}
        else
            text={{'ERROR: can\'t draw date','ErrorMsg'}}
        end
        vim.api.nvim_buf_set_extmark(buf,M.ns,item.row-1,0,{virt_text=text})
    end
end
function M.setup()
    assert(M.conf.path,'conf: small.reminder2.conf.path is not set')
    vim.fn.timer_start(30000,vim.schedule_wrap(M.update),{['repeat']=-1})
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
return M
