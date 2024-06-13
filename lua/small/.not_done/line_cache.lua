local cache = {}
for i = 1, vim.api.nvim_buf_line_count(0) do
    table.insert(cache, i, false)
end
vim.api.nvim_buf_attach(0, false, {
    on_lines = function(_, _, _, first, last, newlast)
        if last < newlast then
            for i = first + 1, last do
                cache[i] = false
            end
            for i = last, newlast - 1 do
                table.insert(cache, i+1, false)
            end
        elseif last == newlast then
            for i = first + 1, last do
                cache[i] = false
            end
        else
            for i = first + 1, newlast do
                cache[i] = false
            end
            for _ = newlast, last - 1 do
                table.remove(cache, newlast+1)
            end
        end
        assert(#cache == vim.api.nvim_buf_line_count(0))
    end
})
vim.keymap.set('n', '§', function()
    for i = 1, vim.api.nvim_buf_line_count(0) do
        cache[i] = true
    end
end)
local ns = vim.api.nvim_create_namespace('test')
vim.api.nvim_set_decoration_provider(ns, {
    on_line = function(_, _, bufnr, row)
        vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, { sign_text = cache[row + 1] and '●' or '○' ,scoped=true})
    end
})
