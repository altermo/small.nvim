local M={}
---@param range Range4
---@param comment string[]
function M.is_commented(range,comment)
    return false
end
---@param range Range4
---@param comment string[]
function M.comment(range,comment)
    local text=vim.api.nvim_buf_get_text(0,range[1],range[2],range[3],range[4],{})
    local start_comment,end_comment=unpack(comment)
    if not end_comment or end_comment=='' then
        for k,_ in ipairs(text) do
            text[k]=start_comment..text[k]
        end
    else
        text[1]=start_comment..text[1]
        text[#text]=text[#text]..end_comment
    end
    vim.api.nvim_buf_set_text(0,range[1],range[2],range[3],range[4],text)
end
---@param range Range4
---@param comment string[]
function M.uncomment(range,comment)

end
---@param range Range4
---@param opts {line?:boolean,comment?:string[]}
function M.toggle(range,opts)
    local comment=opts.comment or vim.split(vim.o.commentstring,'%s',{plain=true})
    if opts.line then
        range=setmetatable({nil,0,nil,#vim.api.nvim_buf_get_lines(0,range[3]-1,range[3],true)[1]},{__index=range})
    end
    if M.is_commented(range,comment) then
        M.uncomment(range,comment)
    else
        M.comment(range,comment)
    end
end
function M.visual()
    local pos1=vim.fn.getpos('v')
    local pos2=vim.fn.getpos('.')
    if pos1[2]>pos2[2] or (pos1[2]==pos2[2] and pos1[3]>pos2[3]) then
        pos1,pos2=pos2,pos1
    end
    pos1={pos1[2]-1,pos1[3]-1}
    pos2={pos2[2]-1,pos2[3]}
    M.toggle({pos1[1],pos1[2],pos2[1],pos2[2]},{comment={'/*','*/'}})
end

if vim.dev then
    vim.keymap.set('x','gc',M.visual)
end
return M
