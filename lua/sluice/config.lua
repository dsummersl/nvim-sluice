local counters = require('sluice.utils.counters')
local logger = require('sluice.utils.logger')

local M = {
  vim = vim
}

function M.remove_autocmds(bufnr)
  local au_ids = M.auto_command_ids_by_bufnr[bufnr]
  if au_ids then
    for _, id in ipairs(au_ids) do
      M.vim.api.nvim_del_autocmd(id)
    end
  end
end

--- Utility function to check if a value matches a string, is in a table, or passes a function test
-- @param obj string|table|function The object to check against
-- @param value any The value to check
-- @return boolean True if the value matches, is in the table, or passes the function test
function M.str_table_fn(obj, value)
  if type(obj) == "nil" then
    return false
  elseif type(obj) == "string" then
    return string.match(value, obj) ~= nil
  elseif type(obj) == "table" then
    for _, v in ipairs(obj) do
      if type(v) == "string" and string.match(value, v) then
        return true
      elseif v == value then
        return true
      end
    end
    return false
  elseif type(obj) == "function" then
    return obj(value)
  end
  return false
end

--- Utility function to check if a value matches is boolean, or a function
-- @param obj boolean|function The object to check against
-- @return boolean
function M.bool_table_fn(obj)
  if type(obj) == "nil" then
    return false
  elseif type(obj) == "boolean" then
    return obj
  elseif type(obj) == "function" then
    return obj()
  end
  return false
end

--- Whether to display the gutter or not.
--
-- Returns boolean indicating whether the gutter is shown on screen or not.
--
-- Show the gutter if:
-- - the buffer is not smaller than the window
-- - the buffer is not a special &buftype
-- - the buffer is not a &previewwindow
-- - the buffer is not a &diff
-- TODO this now needs to take in a win/bufnr b/c its not just the current one.
function M.default_enabled_fn()
  local win_height = M.vim.api.nvim_win_get_height(0)
  local buf_lines = M.vim.api.nvim_buf_line_count(0)
  if win_height >= buf_lines then
    return false
  end
  if M.vim.fn.getwinvar(0, '&buftype') ~= '' then
    return false
  end
  if M.vim.fn.getwinvar(0, '&previewwindow') ~= 0 then
    return false
  end
  if M.vim.fn.getwinvar(0, '&diff') ~= 0 then
    return false
  end

  return true
end

--- Create an enable_fn function that returns true if a specific plugin has contributed lines to the gutter.
--TODO should have a better name (indicate its used by the enabled)
function M.make_has_results_fn(plugin)
  -- TODO this needs to be integration specific
  local function has_results_fn(gutter)
    if not M.default_enabled_fn() then
      return false
    end

    for _, line in pairs(gutter.lines) do
      if line.plugin == plugin then
        return true
      end
    end

    return false
  end

  return has_results_fn
end

local default_settings = {
  enabled = true,
  throttle_ms = 150,
  gutters = {
    {
      plugins = { 'viewport', 'search' },
    },
    {
      plugins = { 'viewport', 'extmark', 'signs' },
    }
  }
}

function M.apply_user_settings(user_settings)
  logger.log('config', 'apply_user_settings')
  if user_settings ~= nil then
    M.vim.validate({ user_settings = { user_settings, 'table', true } })

    -- Validate global options
    if user_settings.enabled ~= nil then
      M.vim.validate({ enabled = { user_settings.enabled, 'boolean' } })
    end
    if user_settings.throttle_ms ~= nil then
      M.vim.validate({ throttle_ms = { user_settings.throttle_ms, 'number' } })
    end
  end

  M.settings = M.vim.tbl_deep_extend('force', M.vim.deepcopy(default_settings), user_settings or {})
end

M.settings = default_settings

return M
