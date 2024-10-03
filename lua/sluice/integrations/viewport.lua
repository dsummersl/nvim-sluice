local config = require('sluice.config')

local M = {
  vim = vim,
}

local default_settings = {
  visible_area_hl = "SluiceViewportVisibleArea",
  cursor_hl = "SluiceViewportCursor",
  events = { 'WinScrolled', 'CursorMoved', 'CursorHold', 'CursorHoldI', 'BufEnter', 'WinEnter', 'VimResized' },
  user_events = {},
}

function M.update(settings, _bufnr)
  local cursor_position = M.vim.api.nvim_win_get_cursor(0)[1]
  local update_settings = M.vim.tbl_deep_extend('keep', settings or {}, default_settings)

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

function M.enable(settings, bufnr)
  local update_settings = M.vim.tbl_deep_extend('keep', settings or {}, default_settings)

  if M.vim.fn.hlexists('SluiceViewportVisibleArea') == 0 then
    M.vim.cmd('hi link SluiceViewportVisibleArea Normal')
  end
  if M.vim.fn.hlexists('SluiceViewportCursor') == 0 then
    M.vim.cmd('hi link SluiceViewportCursor Normal')
  end

  if #update_settings.events > 0 then
    local au_ids = config.trigger_update_on_event(update_settings.events, update_settings.user_events)
    table.insert(M.auto_command_ids_by_bufnr, bufnr, au_ids)
  end

  return update_settings
end

function M.disable(settings, bufnr)
  config.remove_autocmds(bufnr)
end

return M
