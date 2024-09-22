local M = {
  vim = vim,
  enabled = false
}

local gutter = require('sluice.gutter')
local debounce = require('sluice.debounce')

--- Assign autocmds for a group.
---@param group_name string The name of the autocommand group
---@param definitions table[] A list of autocommand definitions
---@return nil
---@param group_name string The name of the autocommand group
---@param definitions table[] A list of autocommand definitions
---@return nil
local nvim_augroup = function(group_name, definitions)
  M.vim.api.nvim_command('augroup ' .. group_name)
  M.vim.api.nvim_command('autocmd!')
  for _, def in ipairs(definitions) do
    local command = table.concat({'autocmd', unpack(def)}, ' ')
    if M.vim.api.nvim_call_function('exists', {'##' .. def[1]}) ~= 0 then
      M.vim.api.nvim_command(command)
    end
  end
  M.vim.api.nvim_command('augroup END')
end

---@return nil
---@return nil
local function update_context()
  if not M.enabled then return end

  gutter.open()
end

M.update_context = debounce(update_context, 100)

---@return nil
---@return nil
function M.enable()
  if M.enabled then return end

  M.enabled = true

  nvim_augroup('sluice', {
    {'DiagnosticChanged', '*',               'lua require("sluice.commands").update_context()'},
    {'WinScrolled', '*',               'lua require("sluice.commands").update_context()'},
    {'CursorMoved', '*',               'lua require("sluice.commands").update_context()'},
    {'CursorHold',  '*',               'lua require("sluice.commands").update_context()'},
    {'CursorHoldI', '*',               'lua require("sluice.commands").update_context()'},
    {'BufEnter',    '*',               'lua require("sluice.commands").update_context()'},
    {'WinEnter',    '*',               'lua require("sluice.commands").update_context()'},
    {'VimResized',  '*',               'lua require("sluice.commands").update_context()'},
  })

  M.update_context()
end

---@return nil
---@return nil
function M.disable()
  if not M.enabled then return end

  M.enabled = false

  nvim_augroup('sluice', {})

  gutter.close()
end

---@return nil
---@return nil
function M.toggle()
  if M.enabled then
    M.disable()
  else
    M.enable()
  end
end

return M
