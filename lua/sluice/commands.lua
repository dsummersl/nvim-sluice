local M = {
  vim = vim,
  enabled = false
}

local gutter = require('sluice.gutter')
local debounce = require('sluice.debounce')

---@return nil
local function update_context()
  if not M.enabled then return end

  gutter.open()
end

M.update_context = debounce(update_context, 100)

---@return nil
function M.enable()
  if M.enabled then return end
  M.enabled = true

  gutter.enable()
  M.update_context()
end

---@return nil
function M.disable()
  if not M.enabled then return end

  M.enabled = false

  nvim_augroup('sluice', {})

  gutter.close()
end

---@return nil
function M.toggle()
  if M.enabled then
    M.disable()
  else
    M.enable()
  end
end

return M
