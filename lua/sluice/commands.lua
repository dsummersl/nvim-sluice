local Sluice = require('sluice.sluice')
local logger = require('sluice.utils.logger')

local M = {
  vim = vim,
  enabled = false,
  au_id = nil,
  sluices = {},
}


---@param bufnr number
---@return nil
local function remove(winid)
  local sluice = M.sluices[winid]
  if sluice ~= nil then
    sluice:close()
  end
  M.sluices[winid] = nil
end

---@return nil
local function update_context(ctx)
  if not M.enabled then return end
  logger.log('commands', 'update_context triggered by ' .. vim.inspect(ctx))

  if ctx.event == "WinClosed" then
    remove(tonumber(ctx.match))
    return
  end

  local windows = vim.api.nvim_list_wins()
  logger.log('commands', 'update_context windows: ' .. vim.inspect(windows))
  for _, win in ipairs(windows) do
    local win_config = vim.api.nvim_win_get_config(win)
    logger.log('commands', 'update_context win_config: ' .. vim.inspect(win_config))
    if win_config.focusable then
      if M.sluices[win] == nil then
        M.sluices[win] = Sluice.new(win)
      end

      M.sluices[win]:update()
    end
  end
end

---@return nil
function M.enable()
  logger.log('commands', 'enable')
  if M.enabled then return end
  M.enabled = true

  -- call once to get things going
  update_context({ event = "" })

  M.au_id = M.vim.api.nvim_create_autocmd({ "WinNew", "WinClosed" }, {
    callback = update_context
  })
end

---@return nil
function M.disable()
  logger.log('commands', 'disable')
  if not M.enabled then return end

  M.enabled = false
  M.vim.api.nvim_del_autocmd(M.au_id)
  M.au_id = nil

  local windows = vim.api.nvim_list_wins()
  for _, win in ipairs(windows) do
    remove(win)
  end
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
