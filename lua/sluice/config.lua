local counters = require('sluice.integrations.counters')

local M = {
  vim = vim
}

--- Utility function to check if a value matches a string, is in a table, or passes a function test
-- @param obj string|table|function The object to check against
-- @param value any The value to check
-- @return boolean True if the value matches, is in the table, or passes the function test
function M.str_table_fn(obj, value)
  if type(obj) == "string" then
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
  plugins = { 'viewport' },
  window = {
    --- Width of the gutter.
    width = 1,

    --- Default highlight to use in the gutter.
    -- This serves as the base linehl highlight for a column in each gutter. Plugins can
    -- override parts of this highlight (typically this is the background color of
    -- areas represented in the gutter of offscreen content)
    default_gutter_hl = 'SluiceColumn',

    --- Whether to display the gutter or not.
    enabled_fn = M.default_enabled_fn,

    --- When there are many matches in an area, how to show the number. Set to 'nil' to disable.
    count_method = nil,

    --- Layout of the gutter. Can be 'left' or 'right'.
    layout = 'right',

    --- Render method for the gutter. Can be 'macro' or 'line'.
    render_method = 'macro',
  },
}

local apply_gutter_settings = function(gutters)
  local result = {}
  for _, gutter in ipairs(gutters) do
    table.insert(result, M.vim.tbl_deep_extend('keep', gutter or {}, default_gutter_settings))
  end
  return result
end

local default_settings = {
  enable = true,
  throttle_ms = 150,
  gutters = apply_gutter_settings{
    {
      plugins = { 'viewport', 'search' },
      window = {
        enabled_fn = M.make_has_results_fn('search'),
        count_method = counters.methods.horizontal_block,
      },
    },
    {
      plugins = { 'viewport', 'signs', 'extmark_signs' },
      window = {
        count_method = '',
      },
      extmarks = {
        hl_groups = '.*'
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
    if user_settings.enable ~= nil then
      M.vim.validate({ enable = { user_settings.enable, 'boolean' } })
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
          ['gutters[' .. i .. '].plugins'] = { gutter.plugins, 'table', true },
        })
        if gutter.window ~= nil then
          M.vim.validate({
            ['gutters[' .. i .. '].window'] = { gutter.window, 'table' },
            ['gutters[' .. i .. '].window.width'] = { gutter.window.width, 'number', true },
            ['gutters[' .. i .. '].window.default_gutter_hl'] = { gutter.window.default_gutter_hl, 'string', true },
            ['gutters[' .. i .. '].window.enabled_fn'] = { gutter.window.enabled_fn, 'function', true },
            ['gutters[' .. i .. '].window.count_method'] = { gutter.window.count_method, {'table'}, true },
            ['gutters[' .. i .. '].window.layout'] = { gutter.window.layout, 'string', true },
            ['gutters[' .. i .. '].window.render_method'] = { gutter.window.render_method, 'string', true },
          })
          if gutter.window.layout ~= nil and gutter.window.layout ~= 'left' and gutter.window.layout ~= 'right' then
            error("gutters[" .. i .. "].window.layout must be 'left' or 'right'")
          end
          if gutter.window.render_method ~= nil and gutter.window.render_method ~= 'macro' and gutter.window.render_method ~= 'line' then
            error("gutters[" .. i .. "].window.render_method must be 'macro' or 'line'")
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
