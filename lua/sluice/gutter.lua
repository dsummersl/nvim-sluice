local M = {
  vim = vim,
  gutters = {},
  lines = {},
}

local ns = M.vim.api.nvim_create_namespace('nvim-sluice')

local config = require('sluice.config')
local window = require('sluice.window')
local convert = require('sluice.convert')

--- Determine whether to throttle some command based on the throttle_ms config.
function M.should_throttle()
  -- TODO ideally this should be a 'tail' throttle rather than a leading edge
  -- type throttle...where an async call is made at the end of the 'throttle_ms' time period.
  local var_exists, last_update_str = pcall(M.vim.api.nvim_buf_get_var, gutter_bufnr, 'sluice_last_update')
  local reltime = M.vim.fn.reltime()

  if not var_exists then
    M.vim.api.nvim_buf_set_var(gutter_bufnr, 'sluice_last_update', tostring(reltime[1]) .. " " .. tostring(reltime[2]))
    return false
  end

  local last_update = M.vim.tbl_map(tonumber, M.vim.split(last_update_str, " "))

  local should_throttle = M.vim.fn.reltimefloat(M.vim.fn.reltime(last_update)) * 1000 < config.settings.throttle_ms

  if not should_throttle then
    M.vim.api.nvim_buf_set_var(gutter_bufnr, 'sluice_last_update', tostring(reltime[1]) .. " " .. tostring(reltime[2]))
  end

  return should_throttle
end

--- Update the gutter with new lines.
function M.update(gutter_bufnr, ns, lines)
  -- TODO store this plugin and its updated value
  -- TODO then replay all the plugins in order.
  local gutter_lines = convert.lines_to_gutter_lines(lines)
  if not gutter_lines then
    M.close()
    return
  end
  window.refresh_buffer(gutter_bufnr, gutter_lines)
  window.refresh_visible_area(gutter_bufnr, ns, gutter_lines)
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
    M.open_gutter(M.gutters[i])
  end
end

--- Open one gutter
function M.open_gutter(gutter)
  local bufnr = M.vim.fn.bufnr()

  local new_gutter_winid = window.create_window(gutter)
  local gutter_winid = gutter.winid
  local gutter_bufnr = gutter.bufnr

  local lines = {}
  for _, v in ipairs(gutter.settings.plugins) do
    local enable_fn = nil
    local update_fn = nil
    if type(v) == "string" then
      -- when there is an integration, load it, and enable it.
      local integration = require('sluice.integrations.' .. v)
      enable_fn = integration.enable
      update_fn = integration.update
    end
    if v.enable ~= nil then
      enable_fn = v.enable
    end
    if v.update ~= nil then
      update_fn = v.update
    end

    if enable_fn ~= nil then
      enable_fn(bufnr)
    end

    if update_fn == nil then
      print("No update function for gutter")
      -- TODO close the gutter
      return
    end

    local integration_lines = update_fn(bufnr)
    for _, v in ipairs(integration_lines) do
      table.insert(lines, v)
    end
  end
  M.lines = lines
  M.update(gutter_bufnr, ns, lines)

  return new_gutter_winid
end

function M.close()
  if gutter_winid and M.vim.api.nvim_win_is_valid(gutter_winid) then
    -- Can't close other windows when the command-line window is open
    if M.vim.api.nvim_call_function('getcmdwintype', {}) ~= '' then
      return
    end

    M.vim.api.nvim_win_close(gutter_winid, true)
  end
end

function M.disable()
  for _, v in ipairs(config.settings.gutters) do
    local integration = require('sluice.integrations.' .. v.integration)
    integration.disable(gutter_bufnr)
  end
end

return M
