--TODO:
--dff as file manager
--have the ability to see a file with another name
---EXAMPLE:
---main_c.lua > c.lua
---main_foo_b.lua > b.lua
--or fast key (maybe autogenerate)
---EXAMPLE:
---main_c.lua > C
---main_foo_b.lua > F
local dff=require'small.dff.dff'
local M={}
---@return number
function M.create_buf()
    local buf=vim.api.nvim_create_buf(true,true)
    vim.api.nvim_buf_set_option(buf,"bufhidden","wipe")
    vim.api.nvim_buf_set_name(buf,'dff-file-explorer')
    return buf
end
---@param conf dff.config
---@param buf number
---@return number
function M.create_win(conf,buf)
    if conf.wintype=='float' then
        return vim.api.nvim_open_win(buf,true,{
            col=conf.wjust,
            row=conf.hjust,
            width=vim.o.columns-conf.wjust*2,
            height=vim.o.lines-conf.hjust*2,
            relative='editor',
        })
    end
    if conf.wintype=='split' then vim.cmd.split() end
    if conf.wintype=='vsplit' then vim.cmd.vsplit() end
    local win=vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win,buf)
    return win
end
---@param path string?
---@param conf dff.config?
function M.open(path,conf)
    conf=conf or require'small.dff.init'.conf
    path=vim.fs.normalize(vim.fn.fnamemodify(path or '.',':p'))
    local buf=M.create_buf()
    M.create_win(conf,buf)
    M.mainloop(buf,path,conf)
end
---@param buf number
---@param path string
---@param conf dff.config
function M.mainloop(buf,path,conf)
    --TODO: M.close_if_float_win
    local ns=vim.api.nvim_create_namespace('dff-file-explorer')
    local search=dff.create_search(vim.fn.readdir(path),conf)
    local rerun
    local function fn()
        if #search.list==1 then
            path=vim.fs.joinpath(path,search.list[1])
            if vim.fn.isdirectory(path)==0 then return vim.cmd.edit(path)
            else
                search=dff.create_search(vim.fn.readdir(path),conf)
                return rerun()
            end
        end
        local key=vim.fn.getcharstr() or ''
        if key=='\r' then key='\n' end
        if key=='' then return vim.cmd.edit(path) end
        if key=='\x80kb' then
            if dff.back(search) then
                repeat path=vim.fs.dirname(path) --[[@as string]] until path=='/' or #vim.fn.readdir(path)~=1
                search=dff.create_search(vim.fn.readdir(path),conf)
            end
            return rerun()
        end
        local ret=dff.send_key(search,key)
        if ret then
            path=vim.fs.joinpath(path,ret)
            if vim.fn.isdirectory(path)==0 then return vim.cmd.edit(path) end
            search=dff.create_search(vim.fn.readdir(path),conf)
        end
        rerun()
    end
    rerun=function()
        M.draw(buf,search,path,ns)
        vim.schedule(fn)
    end
    rerun()
end
---@param buf number
---@param obj dff.search_obj
---@param rpath string
---@param ns number
function M.draw(buf,obj,rpath,ns)
    vim.api.nvim_buf_set_lines(buf,0,-1,false,{})
    for i=obj.range[1],obj.range[2] do
        local path=obj.list[i]
        local text=(vim.fn.isdirectory(vim.fs.joinpath(rpath,path))==1 and '/' or ' ')..path
        if #text==obj.col then text=text..'\r' end
        vim.api.nvim_buf_set_lines(buf,-1,-1,false,{text})
        vim.highlight.range(buf,ns,'Comment',{vim.fn.line'$'-1,1},{vim.fn.line'$'-1,obj.col})
        vim.highlight.range(buf,ns,'Constant',{vim.fn.line'$'-1,obj.col},{vim.fn.line'$'-1,obj.col+1})
        if i-obj.range[1]>vim.o.lines then break end
    end
    local search=vim.fn.join(vim.tbl_map(function (o) return o.k end,obj.history),'')
    vim.api.nvim_buf_set_lines(buf,0,1,false,{':'..search})
    vim.cmd.redraw()
end
return M
