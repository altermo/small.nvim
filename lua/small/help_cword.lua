local M={}
function M.run()
  local word=vim.fn.expand('<cfile>') --[[@as string]]
  if pcall(vim.cmd.help,
    (vim.regex([[vim\.api\.]]):match_str(word) and '%s()' or
      vim.regex([[vim\.uv\.]]):match_str(word) and 'uv.%s()' or
      vim.regex([[vim\.fn\.]]):match_str(word) and '%s()' or
      vim.regex([[vim\.cmd\.]]):match_str(word) and ':%s' or
      vim.regex([[vim\.o\.]]):match_str(word) and "'%s'" or
      vim.regex([[vim\.opt\.]]):match_str(word) and "'%s'" or
      word):format(vim.fn.expand('<cword>'))) then return end
  vim.lsp.buf_request(0,vim.lsp.protocol.Methods.textDocument_hover,vim.lsp.util.make_position_params())
end
return M
