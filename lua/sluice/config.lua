local M = {
  vim = vim
}
local default_settings = {
  enable = true,
  throttle_ms = 150,
  gutters = {
    { integration = 'viewport', },
    { integration = 'signs', },
    { integration = 'search', },
    -- example of a custom gutter:
    -- {
    --   update = function(bufnr)
    --     return {
    --       { lnum = 1, text = 'XX', texthl = 'Normal' }
    --     }
    --   end,
    -- },
  },
}

local apply_user_settings = function(user_settings)
  M.settings = M.vim.tbl_extend('force', user_settings or {}, default_settings)
end

M.apply_user_settings = apply_user_settings
M.settings = default_settings

return M
