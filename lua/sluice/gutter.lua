local M = {
  vim = vim,
  gutters = {},
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

--- Open all gutters configured for this plugin.
function M.open()
  -- if M.should_throttle() then
  --   return
  -- end

  local gutter_count = M.vim.tbl_count(config.settings.gutters)

  for i, v in ipairs(config.settings.gutters) do
    if M.gutters[i] == nil then
      M.gutters[i] = {}
      M.gutters[i].settings = v
      M.gutters[i].gutter_index = i
      M.gutters[i].gutter_count = gutter_count
    end

    M.gutters[i].enabled = v.window.enabled_fn()
    if M.gutters[i].enabled then
      M.open_gutter(M.gutters[i])
    else
      -- TODO support having some gutters enabled and others not enabled
      M.close()
    end
  end
end

--- Open one gutter
function M.open_gutter(gutter)
  local bufnr = M.vim.fn.bufnr()

  window.create_window(gutter)

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
  M.lines[gutter.bufnr] = lines

  M.update(gutter, lines)
end

function M.close()
  for _, gutter in ipairs(M.gutters) do
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
end

return M
