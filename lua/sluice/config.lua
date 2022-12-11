local M = {
  vim = vim
}

local default_gutter_settings = {
  plugins = { 'viewport' },
  window = {
    --- Width of the gutter.
    width = 1,
    --- Default highlight to use in the gutter. 
    -- This serves as the base linehl highlight for a column in each gutter. Plugins can
    -- overide parts of this highlight (typically this is the background color of
    -- areas represented in the gutter of offscreen content)
    default_gutter_hl = 'SluiceColumn',
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

  --- If the buffer is smaller than the window height, don't show gutters.
  hide_on_small_buffers = true,

  gutters = apply_gutter_settings{
    {
      plugins = { 'viewport', 'signs' },
    },
    {
      plugins = { 'viewport', 'search' },
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
  M.settings = M.vim.tbl_deep_extend('keep', user_settings or {}, default_settings)
  apply_gutter_settings(M.settings)
end

M.settings = default_settings

return M
