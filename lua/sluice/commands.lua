local Sluice = require('sluice.sluice')
local logger = require('sluice.utils.logger')

local M = {
  enabled = false,
  au_id = nil,
  sluices = {},
}


---@param winid number
---@return nil
local function remove(winid)
  local sluice = M.sluices[winid]
  if sluice ~= nil then
    sluice:teardown()
  end
  M.sluices[winid] = nil
end

local function is_temp_buffer(bufnr)
  -- Check buffer options to identify a temporary buffer
  local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
  local bufhidden = vim.api.nvim_buf_get_option(bufnr, "bufhidden")
  local modifiable = vim.api.nvim_buf_get_option(bufnr, "modifiable")
  local swapfile = vim.api.nvim_buf_get_option(bufnr, "swapfile")
  local buflisted = vim.api.nvim_buf_get_option(bufnr, "buflisted")

  if not buflisted then
    return true
  end

  -- Return true if it matches the typical traits of a temp buffer
  return buftype == "nowrite" and bufhidden == "wipe"
      and not modifiable and not swapfile
end

---@return nil
local function update_context(ctx)
  if not M.enabled then return end
  logger.log('commands', 'update_context triggered by ' .. vim.inspect(ctx))

  if ctx.event == "WinClosed" then
    local winid = tonumber(ctx.match)
    if type(winid) == "number" then
      remove(winid)
    else
      logger.log('commands', 'update_context unable to remove ' .. ctx.match)
    end
    return
  end

  local windows = vim.api.nvim_list_wins()
  logger.log('commands', 'update_context windows: ' .. vim.inspect(windows))
  for _, win in pairs(windows) do
    if vim.api.nvim_win_is_valid(win) then
      local win_config = vim.api.nvim_win_get_config(win)
      local bufnr = vim.api.nvim_win_get_buf(win)
      local is_temp_buf = is_temp_buffer(bufnr)
      if not is_temp_buf then
        logger.log('commands', 'update_context is_temp_buffer: ' .. vim.inspect(is_temp_buffer(bufnr)) .. ' win: '.. win .. ' bufnr: ' .. bufnr)
        logger.log('commands', 'update_context win_config: ' .. vim.inspect(win_config))
        logger.log('commands',
          'update_context listed: "' .. vim.inspect(vim.api.nvim_buf_get_option(bufnr, 'buflisted')) .. '"')
        if M.sluices[win] == nil then
          M.sluices[win] = Sluice.new(win)
        end

        M.sluices[win]:update()
      elseif is_temp_buf and M.sluices[win] ~= nil then
        remove(win)
      end
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

  M.au_id = vim.api.nvim_create_autocmd({ "WinNew", "BufWinEnter", "WinClosed" }, {
    callback = update_context
  })
end

---@return nil
function M.disable()
  logger.log('commands', 'disable')
  if not M.enabled then return end

  M.enabled = false
  vim.api.nvim_del_autocmd(M.au_id)
  M.au_id = nil

  local windows = vim.api.nvim_list_wins()
  for _, win in pairs(windows) do
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
