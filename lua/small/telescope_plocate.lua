local M={}
function M.run(opt)
    opt=opt or {}
    local pickers=require'telescope.pickers'
    local finders=require'telescope.finders'
    local conf=require'telescope.config'.values
    pickers.new(opt,{
        finder=finders.new_job(function(p)
            if opt.cwd then
                local cwd=opt.cwd==1 and vim.fn.getcwd() or opt.cwd
                return {'plocate','--',vim.fs.normalize(cwd..'/*'),unpack(vim.split(p,' '))}
            end
            return {'plocate','--',unpack(vim.split(p,' '))}
        end),
        previewer = conf.file_previewer(opt),
    }):find()
end
return M
