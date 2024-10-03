local M = {}

M.default_settings = {
  enabled = true,
  throttle_ms = 150,
  gutter = {
    width = 1,
    layout = 'right',
    highlight = 'SluiceGutter'
  },
  window = {
    highlight = 'SluiceWindow'
  }
}

M.settings = vim.deepcopy(M.default_settings)

function M.setup(user_settings)
  M.settings = vim.tbl_deep_extend('force', M.settings, user_settings or {})
  
  -- Set up highlights if they don't exist
  if vim.fn.hlID('SluiceGutter') == 0 then
    vim.api.nvim_set_hl(0, 'SluiceGutter', { fg = '#61afef', bg = '#2c323c' })
  end
  if vim.fn.hlID('SluiceWindow') == 0 then
    vim.api.nvim_set_hl(0, 'SluiceWindow', { fg = '#61afef', bg = '#2c323c' })
  end
end

return M
