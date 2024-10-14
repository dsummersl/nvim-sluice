local config = require('sluice.config')
local logger = require('sluice.utils.logger')
local guards = require('sluice.utils.guards')

local M = {}

---@class ExtmarkSettings : PluginSettings
---@field hl_group string|nil
---@field sign_hl_group string|nil
---@field text string
local default_settings = {
  hl_group = nil,
  sign_hl_group = '.*',
  text = ' ',
  events = { 'DiagnosticChanged' },
  user_events = {},
}

---@param plugin_settings ExtmarkSettings
---@param winid number
---@return Plugin
function M.new(plugin_settings, winid)
  ---@class Extmark : Plugin
  ---@field plugin_settings ExtmarkSettings
  ---@field settings ExtmarkSettings|nil
  ---@field bufnr number
  local extmark = {
    plugin_settings = plugin_settings,
    settings = nil,
    winid = winid,
  }

  local function add_hl_groups(result, bufnr, hl_group_type)
    -- lookup hl_groups or sign_hl_group:
    local hl_groups = extmark.settings[hl_group_type]
    local text = extmark.settings['text']

    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, {details = true})

    for _, mark in ipairs(extmarks) do
      local row = mark[2]
      local details = mark[4]
      if details[hl_group_type] ~= nil and config.str_table_fn(hl_groups, details[hl_group_type]) then
        local row_text = details['sign_text'] or text
        local use_linehl = row_text == ' '
        table.insert(result, {
          lnum = row + 1,
          text = row_text,
          texthl = details[hl_group_type],
          linehl = (use_linehl and details[hl_group_type]) or nil,
          priority = details["priority"],
          plugin = 'extmark',
        })
      end
    end

    return result
  end


  function extmark:enable()
    logger.log("extmark", "enable win: " .. extmark.winid)
    extmark.settings = vim.tbl_deep_extend('keep', extmark.plugin_settings or {}, default_settings)
  end

  function extmark:disable()
    logger.log("extmark", "cleanup: " .. extmark.winid)
  end

  function extmark:get_lines()
    if not guards.win_exists(extmark.winid) then
      logger.log("extmark", "get_lines: " .. extmark.winid .. " not found", "WARN")
      return {}
    end

    local bufnr = vim.api.nvim_win_get_buf(extmark.winid)
    logger.log("extmark", "get_lines: " .. extmark.winid .. " bufnr: " .. bufnr)

    local results = {}
    add_hl_groups(results, bufnr, 'sign_hl_group')
    add_hl_groups(results, bufnr, 'hl_group')
    return results
  end

  extmark:enable()

  return extmark
end

return M
