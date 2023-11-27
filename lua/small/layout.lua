local M={conf={savepath=vim.fn.stdpath('data')..'/layout.json'}}
function M.layout_add_info(layout)
    if layout[1]=='leaf' then
        local buf=vim.api.nvim_win_get_buf(layout[2])
        layout[2]={
            win=layout[2],
            file=vim.api.nvim_buf_get_name(buf),
            winline=vim.fn.winline(),
            curpos=vim.api.nvim_win_get_cursor(layout[2]),
        }
    else
        for _,v in ipairs(layout[2]) do
            M.layout_add_info(v)
        end
    end
end
function M.layout_get()
    local layout=vim.fn.winlayout()
    M.layout_add_info(layout)
    return layout
end
function M.layout_load(layout)
    if layout[1]=='leaf' then
        vim.cmd.edit(layout[2].file)
    elseif layout[1]=='row' then
        for k,v in ipairs(layout[2]) do
            if k>1 then vim.cmd.vsplit() end
            M.layout_load(v)
        end
    elseif layout[1]=='col' then
        for k,v in ipairs(layout[2]) do
            if k>1 then vim.cmd.split() end
            M.layout_load(v)
        end
    end
end
function M.save()
    local layout=M.layout_get()
    local json=vim.json.encode(layout)
    vim.fn.writefile(vim.split(json,'\n'),M.conf.savepath)
end
function M.load()
    local json=table.concat(vim.fn.readfile(M.conf.savepath),'\n')
    local layout=vim.json.decode(json)
    M.layout_load(layout)
end
return M
