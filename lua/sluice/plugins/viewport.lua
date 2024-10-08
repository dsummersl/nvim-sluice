local logger = require('sluice.utils.logger')
local guards = require('sluice.utils.guards')

-- not used, just imported for typing.
require('sluice.plugins.plugin_type')

local M = {
}

---@class ViewportSettings : PluginSettings
---@field visible_area_hl string
---@field cursor_hl string
-- @type ViewportSettings
local default_settings = {
  visible_area_hl = "SluiceViewportVisibleArea",
  cursor_hl = "SluiceViewportCursor",
  events = { 'WinScrolled', 'CursorMoved', 'CursorHold', 'CursorHoldI', 'BufEnter', 'WinEnter', 'VimResized' },
  user_events = {},
}

---@param plugin_settings ViewportSettings
---@param winid number
---@return Plugin
function M.new(plugin_settings, winid)
  ---@class Viewport : Plugin
  ---@field plugin_settings ViewportSettings
  ---@field settings ViewportSettings|nil
  ---@field bufnr number
  -- @type Viewport
  local viewport = {
    plugin_settings = plugin_settings,
    settings = nil,
    winid = winid,
  }

  function viewport:enable()
    logger.log("viewport", "enable win: " .. viewport.winid)
    viewport.settings = vim.tbl_deep_extend('keep', viewport.plugin_settings or {}, default_settings)

    if vim.fn.hlexists('SluiceViewportVisibleArea') == 0 then
      vim.cmd('hi link SluiceViewportVisibleArea Normal')
    end
    if vim.fn.hlexists('SluiceViewportCursor') == 0 then
      vim.cmd('hi link SluiceViewportCursor Normal')
    end
  end

  function viewport:disable()
    logger.log("viewport", "cleanup: " .. viewport.winid)
  end

  function viewport:get_lines()
    if not guards.win_exists(viewport.winid) then
      logger.log("viewport", "get_lines: " .. viewport.winid .. " not found", "WARNING")
      return {}
    end

    local bufnr = vim.api.nvim_win_get_buf(viewport.winid)
    logger.log("viewport", "get_lines: " .. viewport.winid .. " bufnr: " .. bufnr)

    local cursor_position = -1
    if vim.api.nvim_get_current_buf() == viewport.bufnr then
      cursor_position = vim.api.nvim_win_get_cursor(0)[1]
    end

    local lines = {}
    for lnum = vim.fn.line('w0', viewport.winid), vim.fn.line('w$', viewport.winid) do
      local linehl = viewport.settings.visible_area_hl
      local text = " "
      local priority = 0
      if lnum == cursor_position then
        linehl = viewport.settings.cursor_hl
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

  viewport:enable()

  return viewport
end

return M
