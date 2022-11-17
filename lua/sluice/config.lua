local M = {
  vim = vim
}

local default_settings = {
  enable = true,
  throttle_ms = 150,

  --- If the buffer is smaller than the window height, don't show the gutter.
  hide_on_small_buffers = true,

  --- Default highlight to use in the gutter. 
  -- This serves as the base linehl highlight for a column in each gutter. Plugins can
  -- overide parts of this highlight (typically this is the background color of
  -- areas represented in the gutter of offscreen content)
  default_gutter_hl = 'SluiceColumn',

  gutters = {
    {
      plugins = { 'viewport', 'signs' },
      window = {
        width = 1
        -- TODO background highlights, etc
      },
    },
    {
      plugins = { 'viewport', 'search' },
    },
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

local apply_user_settings = function(user_settings)
  M.settings = M.vim.tbl_extend('force', user_settings or {}, default_settings)
end

M.apply_user_settings = apply_user_settings
M.settings = default_settings

return M
