local M={}
function M.run()
  for _,word in ipairs{vim.fn.expand('<cfile>'),vim.fn.expand('<cexpr>')} do
    if pcall(vim.cmd.help,
      (word:match('vim%.api%.') and '%s()' or
        word:match('vim%.uv%.') and 'uv.%s()' or
        word:match('vim%.fn%.') and '%s()' or
        word:match('vim%.cmd%.') and ':%s' or
        word:match('vim%.[wb]?o%.') and "'%s'" or
        word:match('vim%.[wb]?o%[[^]]*%]%.') and "'%s'" or
        word:match('vim%.opt%.') and "'%s'" or
        word):format(vim.fn.expand('<cword>'))) then return end
  end
  vim.lsp.buf_request(0,vim.lsp.protocol.Methods.textDocument_hover,vim.lsp.util.make_position_params())
end
return M
