local M={}
local dates={
    {[[%d%d%d%d/%d%d/%d%d]],'%Y/%m/%d','dd MM yyyy',M=3,y=6},
    {[[%d%d%d%d%-%d%d%-%d%d]],'%Y-%m-%d','dd MM yyyy',M=3,y=6},
    {[[%d%d:%d%d]],'%H:%M','mm hh',h=3},
}
local short_to_long={
    m='min',
    h='hour',
    y='year',
    M='month',
    d='day',
}
local ctrl_a=vim.keycode'<C-a>'
local ctrl_x=vim.keycode'<C-x>'
local function builtin(inc,count)
    vim.api.nvim_feedkeys(count..(inc and ctrl_a or ctrl_x),'n',false)
end
local function increment(inc,count)
    count=count and count~=0 and count or 1
    local line=vim.api.nvim_get_current_line()
    local row=vim.api.nvim_win_get_cursor(0)[1]
    local col=vim.api.nvim_win_get_cursor(0)[2]+1
    local find=line:sub(1,col):find('0x[0-9a-fA-F]+$')
    if find then col=find
    elseif line:sub(col-1,col+1):match('0x[0-9a-fA-F]') then col=col-1 end
    find=line:sub(col):find('%d')
    if not find then return end
    local before=find~=1
    col=find+col-1
    if line:sub(col):match('0x[0-9a-fA-F]') then return builtin(inc,count) end
    for _,v in ipairs(dates) do
        local len=#(v[1]:gsub('%%',''))
        local area=line:sub(math.max(col-len+1,1),col+len-1)
        if col-len+1<1 then
            area=(' '):rep(len-col)..area
        end
        find=area:find(v[1])
        if find then
            local tk=v[3]:sub(find,find)
            local ti=area:sub(find,len+find-1)
            if before and find==len then
                tk=v[3]:sub(1,1)
            end
            local bcol=col+find-1
            col=bcol-(v[tk] or 0)
            local date=os.date('*t',vim.fn.strptime(v[2],ti))
            date[short_to_long[tk]]=date[short_to_long[tk]]+(inc and count or -count)
            ---@diagnostic disable-next-line: param-type-mismatch
            local newdate=os.date(v[2],os.time(date)) --[[@as string]]
            vim.api.nvim_win_set_cursor(0,{row,col-1})
            vim.api.nvim_buf_set_text(0,row-1,bcol-#newdate,row-1,bcol,{newdate})
            return
        end
    end
    return builtin(inc,count)
end
function M.inc(count)
    increment(true,count)
end
function M.dec(count)
    increment(false,count)
end
return M
