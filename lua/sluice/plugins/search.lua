local logger = require('sluice.utils.logger')
local guards = require('sluice.utils.guards')

-- not used, just imported for typing.
require('sluice.plugins.plugin_type')

local M = {}

---@class SearchSettings : PluginSettings
---@field match_hl string
---@field match_line_hl string
---@field priority number
local default_settings = {
  match_hl = "SluiceSearchMatch",
  match_line_hl = "SluiceSearchMatchLine",
  events = { 'CmdlineLeave', 'TextChanged', 'CursorMoved', 'CursorHold' },
  user_events = {},
  priority = 10,
}

---@param plugin_settings SearchSettings
---@param winid number
---@return Plugin
function M.new(plugin_settings, winid)
  ---@class Search : Plugin
  ---@field plugin_settings SearchSettings
  ---@field settings SearchSettings|nil
  ---@field bufnr number
  ---@field priority number
  local search = {
    plugin_settings = plugin_settings,
    settings = nil,
    winid = winid,
  }

  function search:enable()
    logger.log("search", "enable win: " .. search.winid)
    search.settings = vim.tbl_deep_extend('keep', search.plugin_settings or {}, default_settings)

    if vim.fn.hlexists('SluiceSearchMatch') == 0 then
      vim.cmd('hi link SluiceSearchMatch Comment')
    end
    if vim.fn.hlexists('SluiceSearchMatchLine') == 0 then
      vim.cmd('hi link SluiceSearchMatchLine Error')
    end
  end

  function search:disable()
    logger.log("search", "cleanup: " .. search.winid)
  end

  function search:get_lines()
    if not guards.win_exists(search.winid) then
      logger.log("search", "get_lines: " .. search.winid .. " not found", "WARN")
      return {}
    end

    local pattern = vim.fn.getreg('/')
    local current_line = vim.fn.getcurpos(search.winid)[2]

    if pattern == '' or vim.v.hlsearch == 0 then
      return {}
    end

    if vim.o.ignorecase and not vim.o.ignorecase then
      pattern = '\\C' .. pattern
    end

    local lines_with_matches = {}

    local bufnr = vim.api.nvim_win_get_buf(search.winid)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

    for lnum, line in pairs(lines) do
      -- Convert to string to handle special buffers (e.g., ex history) that may return Blob objects
      local line_str = type(line) == 'string' and line or tostring(line)
      if vim.fn.match(line_str, pattern) ~= -1 then
        local texthl = search.settings.match_hl
        if lnum == current_line then
          texthl = search.settings.match_line_hl
        end
        table.insert(lines_with_matches, {
          lnum = lnum,
          -- TODO make the text and texthl configurable
          text = "—",
          texthl = texthl,
          priority = search.settings.priority,
          plugin = 'search',
        })
      end
    end

    return lines_with_matches
  end

  search:enable()

  return search
end

return M
