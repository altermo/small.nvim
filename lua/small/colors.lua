local M={}
function M._get_colorschemes(cb)
    vim.system({'curl','https://neovimcraft.com/db.json'},{},function (out)
        local json=vim.json.decode(out.stdout)
        local colorschemes={}
        for _,v in pairs(json.plugins) do
            if vim.tbl_contains(v.tags,'colorscheme') then
                table.insert(colorschemes,{
                    link=v.link,
                    name=(v.name:find('^n?vim$') or v.name=='neovim') and v.id:match('(.-)/') or v.name,
                    stars=v.stars,
                })
            end
        end
        table.sort(colorschemes,function (a,b) return a.stars>b.stars end)
        M.online_colors_cache=colorschemes
        vim.schedule(cb)
    end)
end
function M.search_colors_online()
    if not M.online_colors_cache then
        M._get_colorschemes(M.search_colors_online) return
    end
    local opts={}
    opts.format_item=function (v)
        return v.name
    end
    require'small.lib.select'(M.online_colors_cache,opts,function (index)
        if not index then return end
        local path=vim.fn.tempname()..'/'
        vim.system({'git','clone','--depth=1',index.link,path},{},vim.schedule_wrap(function ()
            assert(vim.fn.isdirectory(path)==1,'git clone failed')
            local colorpath=vim.fs.joinpath(path,'colors')
            assert(vim.fn.isdirectory(colorpath)==1,'has no colorschemes defined')
            vim.opt.runtimepath:append(path)
            local colorschemes=vim.fn.readdir(colorpath)
            for k,v in ipairs(colorschemes) do
                colorschemes[k]=vim.fn.fnamemodify(v,':r')
            end
            if #colorschemes<2 then
                vim.cmd.colorscheme(assert(colorschemes[1]))
                return
            end
            M.search_colors(colorschemes)
        end))
    end)
end
function M.search_colors(colorschemes)
    if not colorschemes then
        colorschemes=vim.fn.getcompletion('','color')
    end
    local original_colorscheme=vim.api.nvim_exec2('colorscheme',{output=true}).output
    local opts={}
    opts.preview=function(colorscheme)
        if not colorscheme then return end
        vim.cmd.colorscheme(colorscheme)
    end
    opts.cancel=function()
        vim.cmd.colorscheme(original_colorscheme)
    end
    require'small.lib.select'(colorschemes,opts,function (colorscheme)
        if not colorscheme then
            vim.cmd.colorscheme(original_colorscheme)
            return
        end
        vim.cmd.colorscheme(colorscheme)
    end)
end
return M
