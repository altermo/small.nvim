local M={conf={warn_soon_todo_before=60*10},ns=vim.api.nvim_create_namespace('small.reminder2')}
function M.parse_date(date)
    local reg='(%d%d%d%d)%-(%d%d)%-(%d%d)_(%d%d):(%d%d)'
    if not date:match(reg) then date=date..'_00:00' end
    local year,month,day,hour,minute=date:match(reg)
    return {year=year,month=month,day=day,hour=hour,min=minute}
end
function M.today()
    return M.normalize_date(os.date('*t'))
end
function M.normalize_date(date)
    local t=os.date('*t',os.time(date))
    t.hour=0
    t.min=0
    t.sec=0
    ---@diagnostic disable-next-line: param-type-mismatch
    return os.time(t)
end
function M.parse_file_or_buf(file_or_buf)
    local items={}
    local row=0
    for line in type(file_or_buf)=='string' and io.lines(file_or_buf) or vim.iter(vim.api.nvim_buf_get_lines(file_or_buf,0,-1,false)) do
        row=row+1
        local doc=line:match('^%s*[+-]%s*(.*)$')
        if doc then
            local item={row=row,doc=doc:gsub('[^a-zA-Z0-9_-]@.*$','')}
            local run
            local function err(msg)
                item.error=item.error or {}
                table.insert(item.error,msg)
            end
            doc:gsub('[^a-zA-Z0-9_:-]@([a-zA-Z0-9_:-]+)',function (tag)
                if tag:match('^%d%d%d%d%-%d%d%-%d%d$') then
                    if item.date then
                        err('WARN: duplicate date: '..tag)
                    end
                    item.date=M.parse_date(tag)
                elseif tag:match('^%d%d%d%d%-%d%d%-%d%d_%d%d:%d%d$') then
                    if item.date then
                        err('WARN: duplicate date: '..tag)
                    end
                    item.date=M.parse_date(tag)
                    item.time=true
                elseif tag:match('^a%d%d:%d%d$') then
                    --TODO
                    item.only_show_after_time=tag:match('^a(%d%d:%d%d)$')
                elseif tag=='r' then
                    --TODO
                    item.repeated=true
                elseif tag=='q' then
                    item.quick=true
                elseif tag=='i' then
                    item.important=true
                elseif tag:match('^p%d+$') then
                    local n=tonumber(tag:match('^p(%d+)$'))
                    if not n then
                        err('WARN: bad number: '..tag:sub(2))
                    else
                        run=function (i,is)
                            if not i.date then
                                err('WARN: can\'t override nonexsisting date')
                                return
                            end
                            local new_i=setmetatable({date={}},{__index=i})
                            ---@type any
                            local date=os.date('*t',os.time(i.date)-n*86400)
                            if n>0 then
                                new_i.doc='prepare for '..i.doc
                            end
                            for k,v in pairs(date) do
                                if type(v)=='number' then
                                    new_i.date[k]=string.format('%02d',v)
                                end
                            end
                            table.insert(is,new_i)
                        end
                    end
                else
                    item.error=item.error or {}
                    table.insert(item.error,'WARN: unknown tag: '..tag)
                end
            end)
            if run then run(item,items) end
            if item.date or item.error then
                table.insert(items,item)
            end
        end
    end
    return items
end
local function _update(items)
    for item in vim.iter(items) do
        if item.time and os.time()>os.time(item.date) then
            vim.notify(item.doc..' is OVERDUE',vim.log.levels.ERROR)
        elseif item.time and (os.time()+60*10)>os.time(item.date) then
            local min=item.date.min-os.date('*t').min
            if min<0 then min=min+60 end
            vim.notify(item.doc..' is due in '..min..' min',vim.log.levels.WARN)
        end
    end
end
function M.update()
    local items=M.parse_file_or_buf(M.conf.path)
    _update(items)
end
function M.notify_today()
    local items=M.parse_file_or_buf(M.conf.path)
    for item in vim.iter(items) do
        local is_overdue=false
        local message
        if item.time and os.time()>os.time(item.date) then
            is_overdue=true
            message=item.doc
        elseif item.time and (M.today()+86400)>os.time(item.date) then
            message=item.doc..' '..item.date.hour..':'..item.date.min
        elseif item.date and M.today()>os.time(item.date) then
            is_overdue=true
            message=item.doc
        elseif item.date and (M.today()+86400)>os.time(item.date) then
            message=item.doc
        else
            goto continue
        end
        if item.important then
            message='IMPORTANT: '..message
        end
        if is_overdue then
            message=message..' is OVERDUE'
        end
        if item.quick then
            message='QUICK: '..message
        end
        if is_overdue or item.important then
            vim.notify(message,vim.log.levels.ERROR)
        elseif item.quick then
            vim.notify(message,vim.log.levels.WARN)
        else
            vim.notify(message,vim.log.levels.TRACE)
        end
        ::continue::
    end
end
function M.draw(buf)
    vim.api.nvim_buf_clear_namespace(buf,M.ns,0,-1)
    local items=M.parse_file_or_buf(buf)
    for item in vim.iter(items) do
        local text
        if item.error then
            text={{table.concat(item.error,', '),'ErrorMsg'}}
        elseif item.date and ((item.time and os.time()>os.time(item.date)) or (M.today()>os.time(item.date))) then
            text={{'OVERDUE','Error'}}
        elseif item.date and item.time and (M.today()+86400)>os.time(item.date) then
            local t=os.date('*t')
            local min=item.date.min-t.min
            local h=item.date.hour-t.hour
            if min<0 then min=60+min h=h-1 end
            if h==0 then
                text={{'due: ','Comment'},{'in '..min..'m','character'}}
            else
                text={{'due: ','Comment'},{'in '..h..'h '..min..'m','character'}}
            end
        elseif item.date and (M.today()+86400)>os.time(item.date) then
            text={{'due: ','Comment'},{'TODAY','character'}}
        elseif item.date then
            local t=M.normalize_date(item.date)-os.time()+86400
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
        if item.important then
            table.insert(text,{' IMPORTANT','ErrorMsg'})
        end
        if item.quick then
            table.insert(text,{' QUICK','ErrorMsg'})
        end
        vim.api.nvim_buf_set_extmark(buf,M.ns,item.row-1,0,{virt_text=text})
    end
end
function M.sidebar()
    local items=M.parse_file_or_buf(M.conf.path)
    local dates=vim.defaulttable()
    for _,v in ipairs(items) do
        table.insert(dates[v.date.year..'-'..v.date.month..'-'..v.date.day],v)
    end
    local lines={}
    for k,v in vim.spairs(dates) do
        table.sort(v,function(a,b) return os.time(a.date)<os.time(b.date) end)
        table.insert(lines,'')
        table.insert(lines,'#'..k)
        for _,i in ipairs(v) do
            if i.time then
                table.insert(lines,i.date.hour..':'..i.date.min..' '..i.doc)
            else
                table.insert(lines,i.doc)
            end
            if i.important then
                lines[#lines]=lines[#lines]..' (IMPORTANT)'
            end
            if i.quick then
                lines[#lines]=lines[#lines]..' (QUICK)'
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
function M.setup()
    assert(M.conf.path,'conf: small.reminder2.conf.path is not set')
    local items=M.parse_file_or_buf(M.conf.path)
    vim.fn.timer_start(5000,vim.schedule_wrap(function ()
        _update(items)
    end),{['repeat']=-1})
    vim.fn.timer_start(30000,vim.schedule_wrap(function ()
        items=M.parse_file_or_buf(M.conf.path)
    end),{['repeat']=-1})
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
