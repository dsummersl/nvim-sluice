local M = {
  vim = vim,
}

local default_settings = {
  visible_area_hl = "SluiceViewportVisibleArea",
  cursor_hl = "SluiceViewportCursor",
}

function M.update(settings, _bufnr)
  local cursor_position = M.vim.api.nvim_win_get_cursor(0)[1]
  local update_settings = M.vim.tbl_deep_extend('keep', settings.viewport or {}, default_settings)

  local lines = {}
  for lnum = M.vim.fn.line('w0'), M.vim.fn.line('w$') do
    local linehl = update_settings.visible_area_hl
    local text = " "
    local priority = 0
    if lnum == cursor_position then
      linehl = update_settings.cursor_hl
      text = " "
      priority = 1
    end
    table.insert(lines, {
      text = text,
      linehl = linehl,
      lnum = lnum,
      priority = priority,
      plugin = 'viewport',
    })
  end

  return lines
end

function M.enable(_settings, _bufnr)
  if M.vim.fn.hlexists('SluiceViewportVisibleArea') == 0 then
    M.vim.cmd('hi link SluiceViewportVisibleArea Normal')
  end
  if M.vim.fn.hlexists('SluiceViewportCursor') == 0 then
    M.vim.cmd('hi link SluiceViewportCursor Normal')
  end
end

function M.disable(_settings, _bufnr)
end

return M
