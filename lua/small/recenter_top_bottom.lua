local M={current=0}
function M.run()
  M.current=M.current%3+1
  if M.current==3 then vim.cmd.norm{'zb',bang=true}
  elseif M.current==2 then vim.cmd.norm{'zt',bang=true}
  else
    vim.cmd.norm{'zz',bang=true}
    vim.api.nvim_create_autocmd({'CursorMoved','CursorMovedI'},{once=true,callback=function() M.current=0 end,group=vim.api.nvim_create_augroup('Cz',{clear=true})})
  end
end
return M
