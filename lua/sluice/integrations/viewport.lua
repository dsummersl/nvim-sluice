local M = {
  vim = vim,
}

function M.update(settings, bufnr)
  local cursor_position = M.vim.api.nvim_win_get_cursor(0)[1]
  local visible_area_hl = 'SluiceVisibleArea'
  local cursor_hl = 'SluiceCursor'
  if settings.viewport ~= nil then
    if settings.viewport.visible_area_hl ~= nil then
      visible_area_hl = settings.viewport.visible_area_hl
    end
    if settings.viewport.cursor_hl ~= nil then
      cursor_hl = settings.viewport.cursor_hl
    end
  end

  local lines = {}
  for lnum = M.vim.fn.line('w0'), M.vim.fn.line('w$') do
    local linehl = visible_area_hl
    local text = " "
    local priority = 0
    if lnum == cursor_position then
      linehl = cursor_hl
      text = " "
      priority = 1
    end
    table.insert(lines, {
      text = text,
      linehl = linehl,
      lnum = lnum,
      priority = priority,
    })
  end

  return lines
end

function M.enable(settings, bufnr)
end

function M.disable(settings, bufnr)
end

return M
