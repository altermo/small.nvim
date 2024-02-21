local M={}
M.ns=vim.api.nvim_create_namespace('small_winvis')
function M.setup()
    vim.api.nvim_set_decoration_provider(M.ns,{on_win=function (_,winid,bufnr,_)
        if winid~=vim.api.nvim_get_current_win() then return end
        local mode=vim.fn.mode()
        if not ({v=true,V=true,['\x16']=true})[mode] then return end
        if not vim.tbl_isempty(vim.api.nvim_get_hl(0, {name='Visual'})) then
            ---@type table
            M.visual_hl_info=vim.api.nvim_get_hl(0, {name='Visual'})
            vim.api.nvim_set_hl(0, 'SmallWinvisVisual', M.visual_hl_info)
            vim.api.nvim_set_hl(0, 'Visual', {})
        end
        local pos1=vim.fn.getpos('v')
        pos1={pos1[2]-1,pos1[3]-1}
        local pos2=vim.fn.getpos('.')
        pos2={pos2[2]-1,pos2[3]-1}
        if mode=='\x16' then
            local diff=math.abs(pos1[2]-pos2[2])
            if pos1[2]>pos2[2] then
                pos1[2]=pos2[2]
            else
                pos2[2]=pos1[2]
            end
            mode=mode..tostring(diff+1)
        end
        local region=vim.region(bufnr,pos1,pos2,mode,true)
        for linenr,cols in pairs(region) do
            local end_row
            if cols[2]==-1 then
                end_row=linenr+1
                cols[2]=0
            end
            vim.api.nvim_buf_set_extmark(bufnr,M.ns,linenr,cols[1],{
                hl_group='SmallWinvisVisual',
                end_row=end_row,
                end_col=cols[2],
                strict=false,
                ephemeral=true,
            })
        end
    end})
end
if vim.dev then
    M.setup()
end
return M
