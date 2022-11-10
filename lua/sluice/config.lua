local M = {}
local default_settings = {
  enable = true,
  throttle_ms = 150,
}

local apply_user_settings = function(user_settings)
  M.settings = vim.tbl_extend('force', default_settings, user_settings or {})
end

M.apply_user_settings = apply_user_settings
apply_user_settings()

return M
