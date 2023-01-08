local M = {
  vim = vim,
  gutters = nil,
  lines = {},
  gutter_lines = {},
}

local config = require('sluice.config')
local window = require('sluice.window')
local convert = require('sluice.convert')

--- Update the gutter with new lines.
function M.update(gutter, lines)
  -- TODO store this plugin and its updated value
  -- TODO then replay all the plugins in order.
  local gutter_lines = convert.lines_to_gutter_lines(gutter.settings, lines)
  window.refresh_buffer(gutter.bufnr, gutter_lines)
  window.refresh_highlights(gutter.bufnr, gutter.ns, gutter_lines)
  M.gutter_lines[gutter.bufnr] = gutter_lines
end

--- Get plugin lines for each gutter
function M.get_lines(gutter)
  local bufnr = M.vim.fn.bufnr()
  local lines = {}
  for _, plugin in ipairs(gutter.settings.plugins) do
    local enable_fn = nil
    local update_fn = nil

    if type(plugin) == "string" then
      -- when there is an integration, load it, and enable it.
      plugin = require('sluice.integrations.' .. plugin)
    end

    if plugin.enable ~= nil then
      enable_fn = plugin.enable
    end
    if plugin.update ~= nil then
      update_fn = plugin.update
    end

    if enable_fn ~= nil then
      enable_fn(gutter.settings, bufnr)
    end

    if update_fn == nil then
      print("No update function for gutter")
      -- TODO close the gutter
      return
    end

    local integration_lines = update_fn(gutter.settings, bufnr)
    for _, il in ipairs(integration_lines) do
      table.insert(lines, il)
    end
  end

  return lines
end

--- Create initial gutter settings
function M.init_gutters(config)
  local gutter_count = M.vim.tbl_count(config.settings.gutters)
  local gutters = {}
  for i, v in ipairs(config.settings.gutters) do
    if gutters[i] == nil then
      gutters[i] = {}
      gutters[i].settings = v
      gutters[i].enabled = true
    end
  end

  return gutters
end

--- Open all gutters configured for this plugin.
function M.open()
  -- if M.should_throttle() then
  --   return
  -- end

  if M.gutters == nil then
    M.gutters = M.init_gutters(config)
  end

  for i, gutter_settings in ipairs(config.settings.gutters) do
    local gutter = M.gutters[i]
    gutter.lines = M.get_lines(gutter)
    gutter.enabled = gutter_settings.window.enabled_fn(gutter)
  end

  for i, v in ipairs(config.settings.gutters) do
    if M.gutters[i].enabled then
      M.open_gutter(i)
    else
      M.close_gutter(M.gutters[i])
    end
  end
end

--- Open one gutter
function M.open_gutter(gutter_index)
  local gutter = M.gutters[gutter_index]

  window.create_window(M.gutters, gutter_index)

  M.update(gutter, gutter.lines)
end

--- Close one gutter
function M.close_gutter(gutter)
  -- Can't close other windows when the command-line window is open
  if M.vim.api.nvim_call_function('getcmdwintype', {}) ~= '' then
    return
  end

  for _, plugin in ipairs(gutter.settings.plugins) do
    local disable_fn = nil
    if type(plugin) == "string" then
      -- when there is an integration, load it, and enable it.
      local integration = require('sluice.integrations.' .. plugin)
      disable_fn = integration.disable
    end
    if plugin.disable ~= nil then
      disable_fn = plugin.disable
    end

    if gutter.bufnr ~= nil then
      disable_fn(gutter.settings, gutter.bufnr)
    end
  end

  if gutter.winid ~= nil then
    M.vim.api.nvim_win_close(gutter.winid, true)
    gutter.winid = nil
  end
end

function M.close()
  for _, gutter in ipairs(M.gutters) do
    M.close_gutter(gutter)
  end
end

return M
