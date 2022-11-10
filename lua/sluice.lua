local M = {
  vim = vim
}

M.setup = function(settings)
  local config = require('sluice.config')
  config.apply_user_settings(settings)

  M.vim.api.nvim_command('command! SluiceEnable  lua require("sluice.commands").enable()')
  M.vim.api.nvim_command('command! SluiceDisable lua require("sluice.commands").disable()')
  M.vim.api.nvim_command('command! SluiceToggle lua require("sluice.commands").toggle()')

  if config.settings.enable then
    require("sluice.commands").enable()
  else
    require("sluice.commands").disable()
  end
end

M.setup()

return M
