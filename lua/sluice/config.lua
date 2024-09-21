local counters = require('sluice.integrations.counters')

local M = {
  vim = vim
}

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
function M.default_enabled_fn(_gutter)
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

local default_gutter_settings = {
  --- Width of the gutter.
  width = 1,

  --- Default highlight to use in the gutter.
  -- This serves as the base linehl highlight for a column in each gutter. Plugins can
  -- override parts of this highlight (typically this is the background color of
  -- areas represented in the gutter of offscreen content)
  default_gutter_hl = 'SluiceColumn',

  --- Whether to display the gutter or not.
  enabled = M.default_enabled_fn,

  --- When there are many matches in an area, how to show the number. Set to 'nil' to disable.
  count_method = nil,

  --- Layout of the gutter. Can be 'left' or 'right'.
  layout = 'right',

  --- Render method for the gutter. Can be 'macro' or 'line'.
  render_method = 'macro',

  integrations = { 'viewport' },
}

local apply_gutter_settings = function(gutters)
  local result = {}
  for _, gutter in ipairs(gutters) do
    table.insert(result, M.vim.tbl_deep_extend('keep', gutter or {}, default_gutter_settings))
  end
  return result
end

local default_settings = {
  enabled = true,
  throttle_ms = 150,
  gutters = apply_gutter_settings{
    {
      enabled = M.make_has_results_fn('search'),
      count_method = counters.methods.horizontal_block,
      integrations = { 'viewport', 'search' },
    },
    {
      count_method = nil,
      integrations = { 'viewport', 'signs', 'extmark' },
      extmark = {
        sign_hl_groups = '.*'
      },
      signs = {
        -- TODO rename to groups?
        group = '.*'
      }
    },
  }
}

function M.apply_user_settings(user_settings)
  if user_settings ~= nil then
    M.vim.validate({ user_settings = { user_settings, 'table', true} })

    -- Validate global options
    if user_settings.enabled ~= nil then
      M.vim.validate({ enabled = { user_settings.enabled, 'boolean' } })
    end
    if user_settings.throttle_ms ~= nil then
      M.vim.validate({ throttle_ms = { user_settings.throttle_ms, 'number' } })
    end

    -- Validate gutters
    if user_settings.gutters ~= nil then
      M.vim.validate({ gutters = { user_settings.gutters, 'table' } })
      for i, gutter in ipairs(user_settings.gutters) do
        M.vim.validate({
          ['gutters[' .. i .. ']'] = { gutter, 'table' },
          ['gutters[' .. i .. '].integrations'] = { gutter.integrations, 'table', true },
        })
        if gutter ~= nil then
          M.vim.validate({
            ['gutters[' .. i .. ']'] = { gutter, 'table' },
            ['gutters[' .. i .. '].width'] = { gutter.width, 'number', true },
            ['gutters[' .. i .. '].default_gutter_hl'] = { gutter.default_gutter_hl, 'string', true },
            ['gutters[' .. i .. '].enabled'] = { gutter.enabled, { 'function', 'boolean' }, true },
            ['gutters[' .. i .. '].count_method'] = { gutter.count_method, {'table'}, true },
            ['gutters[' .. i .. '].layout'] = { gutter.layout, 'string', true },
            ['gutters[' .. i .. '].render_method'] = { gutter.render_method, 'string', true },
          })
          if gutter.layout ~= nil and gutter.layout ~= 'left' and gutter.layout ~= 'right' then
            error("gutters[" .. i .. "].layout must be 'left' or 'right'")
          end
          if gutter.render_method ~= nil and gutter.render_method ~= 'macro' and gutter.render_method ~= 'line' then
            error("gutters[" .. i .. "].render_method must be 'macro' or 'line'")
          end
        end
      end
    end
  end

  M.settings = M.vim.tbl_deep_extend('force', M.vim.deepcopy(default_settings), user_settings or {})
  if user_settings ~= nil and user_settings.gutters ~= nil then
    M.settings.gutters = apply_gutter_settings(user_settings.gutters)
  end
end

M.settings = default_settings

return M
