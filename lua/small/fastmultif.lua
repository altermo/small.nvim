local M={conf={labels='23456789',flabels='asdfghjklzxcvbnmqwertyuiop'}}
M.ns=vim.api.nvim_create_namespace'small_fastmultif'
function M.create_hl()
    M.labels={}
    local labels=M.conf.labels
    for i=1,#labels do
        if vim.str_utf_start(labels,i)==0 then
            table.insert(M.labels,labels:sub(i,i+vim.str_utf_end(labels,i)))
        end
    end
    M.flabels={}
    local flabels=M.conf.flabels
    for i=1,#flabels do
        if vim.str_utf_start(flabels,i)==0 then
            table.insert(M.flabels,flabels:sub(i,i+vim.str_utf_end(flabels,i)))
        end
    end
    for _,v in ipairs({'FlashLabel','Substitute'}) do
        if vim.api.nvim_get_hl(0,{create=false,name=v}) then
            vim.api.nvim_set_hl(0,'SmallFastmultif',{link=v})
            return
        end
    end
    error''
end
function M.ffind(opts)
    opts=opts or {}
    local char=vim.fn.getcharstr()
    if #char~=1 then return end
    M.buf=vim.api.nvim_get_current_buf()
    M.win=vim.api.nvim_get_current_win()
    M.create_hl()
    if char=='\n' then char='\0' end
    local instances
    if opts.backwards then
        instances=M.find_prev_instances(char,#M.flabels)
    else
        instances=M.find_next_instances(char,#M.flabels)
    end
    for k,v in ipairs(instances) do
        vim.api.nvim_buf_set_extmark(0,M.ns,v[1]-1,v[2],{
            virt_text={{M.flabels[k],'SmallFastmultif'}},
            virt_text_pos='overlay',
        })
    end
    vim.cmd.redraw()
    local l=vim.fn.getcharstr()
    for k,v in ipairs(instances) do
        if l==M.flabels[k] then
            M.clear_highlight()
            vim.api.nvim_win_set_cursor(0,v)
            return
        end
    end
    M.clear_highlight()
end
function M.rffind()
    M.ffind{backwards=true}
end
function M.rfind()
    M.find{backwards=true}
end
function M.find(opts)
    opts=opts or {}
    if vim.fn.mode()~='n' then error('only in normal mode supported') end
    if vim.fn.mode(true):find'^ni' or vim.fn.reg_recording()~='' or vim.fn.reg_executing()~='' then
        local char=vim.fn.getcharstr()
        local instances
        if opts.backwards then
            instances=M.find_prev_instances(char,1)
        else
            instances=M.find_next_instances(char,1)
        end
        if #instances<1 then return true end
        vim.api.nvim_win_set_cursor(0,instances[1])
        return
    end
    local char=vim.fn.getcharstr()
    if #char~=1 then return end
    if char=='\n' then char='\0' end
    M.buf=vim.api.nvim_get_current_buf()
    M.win=vim.api.nvim_get_current_win()
    M.create_hl()
    if M.create_highlight(char,opts) then return end
    vim.on_key(function()
        M.clear_maps()
        M.clear_highlight()
        vim.on_key(nil,M.ns)
    end,M.ns)
    M.set_maps()
end
function M.clear_highlight()
    vim.api.nvim_buf_clear_namespace(M.buf,M.ns,0,-1)
    vim.cmd.mode()
end
function M.create_highlight(char,opts)
    local instances
    if opts.backwards then
        instances=M.find_prev_instances(char,#M.labels+1)
    else
        instances=M.find_next_instances(char,#M.labels+1)
    end
    if #instances<1 then return true end
    local next=table.remove(instances,1)
    vim.api.nvim_win_set_cursor(0,next)
    if #instances<1 then return true end
    for k,v in ipairs(instances) do
        vim.api.nvim_buf_set_extmark(0,M.ns,v[1]-1,v[2],{
            virt_text={{M.labels[k],'SmallFastmultif'}},
            virt_text_pos='overlay',
        })
    end
    M.positions=instances
end
function M.find_next_instances(char,times)
    local cursor=vim.api.nvim_win_get_cursor(0)
    local lines=vim.api.nvim_buf_get_lines(0,cursor[1]-1,-1,true)
    local ret={}
    for row,line in ipairs(lines) do
        local pos=line:find(char,row==1 and cursor[2]+2 or 1,true)
        while pos do
            table.insert(ret,{row+cursor[1]-1,pos-1})
            if times<=#ret then return ret end
            pos=line:find(char,pos+1,true)
        end
    end
    return ret
end
function M.find_prev_instances(char,times)
    local cursor=vim.api.nvim_win_get_cursor(0)
    local lines=vim.api.nvim_buf_get_lines(0,0,cursor[1],true)
    lines=vim.fn.reverse(lines)
    local ret={}
    for row,line in ipairs(lines) do
        local rline=line:reverse()
        local pos=rline:find(char,row==1 and #rline-cursor[2]+1 or 1,true)
        while pos do
            table.insert(ret,{#lines-row+1,#line-pos})
            if times<=#ret then return ret end
            pos=rline:find(char,pos+1,true)
        end
    end
    return ret
end
function M.clear_maps()
    if not M.maps then error'' end
    for k,v in pairs(M.maps) do
        vim.schedule(function ()
            if v==true then
                vim.api.nvim_buf_del_keymap(M.buf,'n',tostring(k))
            else
                vim.fn.mapset(v)
            end
            M.positions=nil
        end)
    end
    M.maps=nil
end
function M.set_maps()
    if M.maps then error'' end
    M.maps={}
    for k,c in ipairs(M.labels) do
        local map=vim.fn.maparg(c,'n',false,true)
        if map.buffer==1 then
            M.maps[c]=map
        else
            M.maps[c]=true
        end
        vim.keymap.set('n',c,function ()
            M.goto(k)
        end,{nowait=true,buffer=M.buf})
    end
end
function M.goto(k)
    if not M.positions then return end
    vim.api.nvim_win_set_cursor(M.win,M.positions[k])
end
return M
