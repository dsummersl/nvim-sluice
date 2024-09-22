local M = {
  vim = vim,
  gutters = nil,
  gutter_lines = {},
}

local config = require('sluice.config')
local window = require('sluice.window')
local convert = require('sluice.convert')

--- Update the gutter with new lines.
---@param gutter table The gutter object to update
---@param lines table[] The new lines to set in the gutter
---@return nil
function M.update(gutter, lines)
  local gutter_settings = config.settings.gutters[gutter.index]
  local gutter_lines = convert.lines_to_gutter_lines(gutter_settings, lines)
  M.vim.schedule(function()
    window.set_gutter_lines(gutter.bufnr, gutter_lines, gutter_settings.count_method, gutter_settings.width)
    window.refresh_highlights(gutter.bufnr, gutter.ns, gutter_lines)
  end)
  M.gutter_lines[gutter.bufnr] = gutter_lines
end

--- Get all integration lines for a gutter
---@param gutter table The gutter object to get lines for
---@return table[] lines The integration lines for the gutter
function M.get_lines(gutter)
  local bufnr = M.vim.fn.bufnr()
  local lines = {}
  local gutter_settings = config.settings.gutters[gutter.index]
  for _, integration_settings in ipairs(gutter_settings.integrations) do
    local enable_fn = nil
    local update_fn = nil

    local plugin = nil
    local plugin_settings = nil
    if type(integration_settings) == "table" then
      plugin = require('sluice.integrations.' .. integration_settings[1])
      plugin_settings = integration_settings[2]
    else
      -- a string
      plugin = require('sluice.integrations.' .. integration_settings)
      plugin_settings = nil
    end

    if plugin.enable ~= nil then
      enable_fn = plugin.enable
    end
    if plugin.update ~= nil then
      update_fn = plugin.update
    end

    if enable_fn ~= nil then
      -- TODO update all the integrations
      enable_fn(plugin_settings, bufnr)
    end

    if update_fn == nil then
      print("No update function for gutter")
      -- TODO close the gutter
      return
    end

    local integration_lines = update_fn(plugin_settings, bufnr)
    for _, il in ipairs(integration_lines) do
      table.insert(lines, il)
    end
  end

  return lines
end

--- Create initial gutter settings
---@param config table The configuration object
---@return table[] gutters The initialized gutter settings
function M.init_gutters(config)
  local gutters = {}
  for i, v in ipairs(config.settings.gutters) do
    gutters[i] = {
      index = i,
      enabled = v.enabled
    }
  end

  return gutters
end

--- Open all gutters configured for this plugin.
---@return nil
function M.open()
  -- if M.should_throttle() then
  --   return
  -- end

  -- TODO we need some better way to init the gutters but only minimally?
  if M.gutters == nil or #M.gutters ~= #config.settings.gutters then
    M.gutters = M.init_gutters(config)
  end

  for i, gutter_settings in ipairs(config.settings.gutters) do
    local gutter = M.gutters[i]
    gutter.lines = M.get_lines(gutter)
    gutter.enabled = gutter_settings.enabled(gutter)
  end

  M.vim.schedule(function()
    for i, _ in ipairs(config.settings.gutters) do
      if M.gutters[i].enabled then
        M.open_gutter(i)
      else
        M.close_gutter(M.gutters[i])
      end
    end
  end)
end

--- Open one gutter
---@param gutter_index number The index of the gutter to open
---@return nil
function M.open_gutter(gutter_index)
  local gutter = M.gutters[gutter_index]

  window.create_window(M.gutters, gutter_index)

  M.update(gutter, gutter.lines)
end

--- Close one gutter
---@param gutter table The gutter object to close
---@return nil
function M.close_gutter(gutter)
  -- Can't close other windows when the command-line window is open
  if M.vim.api.nvim_call_function('getcmdwintype', {}) ~= '' then
    return
  end

  local gutter_settings = config.settings.gutters[gutter.index]
  for _, plugin in ipairs(gutter_settings.integrations) do
    local disable_fn = nil
    if type(plugin) == "string" then
      -- when there is an integration, load it, and enable it.
      local integration = require('sluice.integrations.' .. plugin)
      disable_fn = integration.disable
    else
      local integration = require('sluice.integrations.' .. plugin[1])
      disable_fn = integration.disable
    end

    if M.vim.fn.bufexists(gutter.bufnr) ~= 0 then
      disable_fn(gutter_settings, gutter.bufnr)
    end
  end

  if vim.fn.win_id2win(gutter.winid) ~= 0 then
    M.vim.api.nvim_win_close(gutter.winid, true)
    gutter.winid = nil
  end
end

--- Close all gutters
---@return nil
function M.close()
  for _, gutter in ipairs(M.gutters) do
    M.close_gutter(gutter)
  end
end

return M
