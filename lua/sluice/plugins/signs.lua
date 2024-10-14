local config = require('sluice.config')
local logger = require('sluice.utils.logger')
local guards = require('sluice.utils.guards')

local M = {}

---@class SignsSettings : PluginSettings
---@field group string
local default_settings = {
  group = '.*',
  events = { 'DiagnosticChanged' },
  user_events = {},
}

--- Get a table with keys set to the `name` of each sign that is defined.
local function sign_getdefined()
  local get_defined = vim.fn.sign_getdefined()
  local signs_defined = {}
  for _, v in ipairs(get_defined) do
    signs_defined[v["name"]] = v
  end

  return signs_defined
end


---@param plugin_settings SignsSettings
---@param winid number
---@return Plugin
function M.new(plugin_settings, winid)
  ---@class Signs : Plugin
  ---@field plugin_settings SignsSettings
  ---@field settings SignsSettings|nil
  ---@field bufnr number
  local signs = {
    plugin_settings = plugin_settings,
    settings = nil,
    winid = winid,
  }

  function signs:enable()
    logger.log("signs", "enable win: " .. signs.winid)
    signs.settings = vim.tbl_deep_extend('keep', signs.plugin_settings or {}, default_settings)
  end

  function signs:disable()
    logger.log("signs", "cleanup: " .. signs.winid)
  end

  function signs:get_lines()
    if not guards.win_exists(signs.winid) then
      logger.log("signs", "get_lines: " .. signs.winid .. " not found", "WARN")
      return {}
    end

    local get_defined = sign_getdefined()
    local bufnr = vim.api.nvim_win_get_buf(signs.winid)
    local get_placed = vim.fn.sign_getplaced(bufnr, { group = '*' })

    local result = {}
    for _, v in ipairs(get_placed[1]["signs"]) do
      if config.str_table_fn(signs.settings.group, v["name"]) and v["name"] ~= "" then
        local line = vim.tbl_extend('force', get_defined[v["name"]], v)
        line.plugin = 'signs'
        table.insert(result, line)
      end
    end

    return result
  end

  signs:enable()

  return signs
end

return M
