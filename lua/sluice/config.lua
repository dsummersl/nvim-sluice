local logger = require('sluice.utils.logger')

local M = { }

function M.remove_autocmds(bufnr)
  local au_ids = M.auto_command_ids_by_bufnr[bufnr]
  if au_ids then
    for _, id in pairs(au_ids) do
      vim.api.nvim_del_autocmd(id)
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
    for _, v in pairs(obj) do
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

--- @class SluiceSettings
--- @field enabled boolean|nil
--- @field throttle_ms number|nil
--- @field gutters GutterSettings[]|nil
local default_settings = {
  enabled = true,
  throttle_ms = 150,
  gutters = {
    {
      plugins = { 'viewport', 'extmark', 'signs' },
    }
  }
}

--- Apply user settings to the default settings.
--- @param user_settings SluiceSettings
function M.apply_user_settings(user_settings)
  logger.log('config', 'apply_user_settings')
  if user_settings ~= nil then
    vim.validate({ user_settings = { user_settings, 'table', true } })

    -- Validate global options
    if user_settings.enabled ~= nil then
      vim.validate({ enabled = { user_settings.enabled, 'boolean' } })
    end
    if user_settings.throttle_ms ~= nil then
      vim.validate({ throttle_ms = { user_settings.throttle_ms, 'number' } })
    end
  end

  M.settings = vim.tbl_deep_extend('force', vim.deepcopy(default_settings), user_settings or {})
end

M.settings = default_settings

return M
