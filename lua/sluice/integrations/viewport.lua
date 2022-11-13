local M = {
  vim = vim
}

function M.update(bufnr)
  local cursor_position = M.vim.api.nvim_win_get_cursor(0)[1]

  local lines = {}
  for lnum = M.vim.fn.line('w0'), M.vim.fn.line('w$') do
    local linehl = 'SluiceVisibleArea'
    if lnum == cursor_position then
      linehl = 'SluiceCursor'
    end
    table.insert(lines, {
      text = "  ",
      linehl = linehl,
      priority = 1,
      lnum = lnum,
    })
  end

  return lines
end

function M.enable(bufnr)
  return M.update
end

function M.disable(bufnr)
end

return M
