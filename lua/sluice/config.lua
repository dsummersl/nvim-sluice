local counters = require('sluice.integrations.counters')

local M = {
  vim = vim
}

--- Whether to display the gutter or not.
--
-- Returns boolean indicating whether the gutter is shown on screen or not.
--
-- Show the gutter if:
-- - the buffer is not smaller than the window
-- - the buffer is not a special &buftype
-- - the buffer is not a &previewwindow
-- - the buffer is not a &diff
function M.default_enabled_fn(gutter)
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
function M.make_plugin_has_results_enabled_fn(plugin)
  local function enabled_fn(gutter)
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

  return enabled_fn
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
    count_method = counters.methods.horizontal_block,
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
        -- TODO this should be a method that maps to a function ("has results")
        enabled_fn = M.make_plugin_has_results_enabled_fn('search'),
      },
    },
    {
      plugins = { 'viewport', 'signs', 'extmark_signs' },
      window = {
        count_method = '',
      },
      extmarks = {
      }
    },
    -- {
    --   plugins = { 'viewport',
    -- },
    --   viewport = {
    --     cursor_hl = 'IncSearch',
    --   }
    -- },
    --- Example custom getter function:
    -- {
    --   plugins = {
    --     'viewport',
    --     {
    --       update = function(bufnr)
    --         return {
    --           { lnum = 1, text = 'X', texthl = 'Normal' },
    --           { lnum = 11, text = 'X', texthl = 'Normal' },
    --           { lnum = 21, text = 'X', texthl = 'Normal' },
    --           { lnum = 31, text = 'X', texthl = 'Normal' },
    --           { lnum = 41, text = 'X', texthl = 'Normal' },
    --           { lnum = 51, text = 'X', texthl = 'Normal' },
    --         }
    --       end,
    --     }
    --   },
    -- },
  }
}

function M.apply_user_settings(user_settings)
  M.vim.validate({ config = { user_settings, 'table'} })
  -- TODO apply more validate actions here, see here for examples:
  -- /Users/danesummers/.local/share/nvim/lazy/mini.nvim/lua/mini/diff.lua#851

  M.settings = M.vim.tbl_deep_extend('force', M.vim.deepcopy(default_settings), user_settings or {})
  apply_gutter_settings(M.settings)
end

M.settings = default_settings

return M
