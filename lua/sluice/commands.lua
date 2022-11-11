local M = {
  vim = vim
}

local window = require('sluice.window')
local config = require('sluice.config')

local winid = nil
local bufnr = M.vim.api.nvim_create_buf(false, true)
local ns = M.vim.api.nvim_create_namespace('nvim-sluice')

--- Assign autocmds for a group.
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

--- Determine whether to throttle some command based on the throttle_ms config.
function M.should_throttle()
  -- TODO ideally this should be a 'tail' throttle rather than a leading edge
  -- type throttle...where an async call is made at the end of the 'throttle_ms' time period.
  local var_exists, last_update_str = pcall(M.vim.api.nvim_buf_get_var, bufnr, 'sluice_last_update')
  local reltime = M.vim.fn.reltime()

  if not var_exists then
    M.vim.api.nvim_buf_set_var(bufnr, 'sluice_last_update', tostring(reltime[1]) .. " " .. tostring(reltime[2]))
    return false
  end

  local last_update = M.vim.tbl_map(tonumber, M.vim.split(last_update_str, " "))

  local should_throttle = M.vim.fn.reltimefloat(M.vim.fn.reltime(last_update)) * 1000 < config.settings.throttle_ms

  if not should_throttle then
    M.vim.api.nvim_buf_set_var(bufnr, 'sluice_last_update', tostring(reltime[1]) .. " " .. tostring(reltime[2]))
  end

  return should_throttle
end

function M.update_context()
  if M.vim.fn.getwinvar(0, '&buftype') ~= '' then return M.close() end
  if M.vim.fn.getwinvar(0, '&previewwindow') ~= 0 then return M.close() end
  if M.vim.fn.getwinvar(0, '&diff') ~= 0 then return M.close() end

  M.open()
end

function M.close()
  window.close(winid)
  winid = nil
end

function M.open()
  if M.should_throttle() then
    return
  end

  winid = window.open(winid, bufnr, ns)
end

function M.enable()
  nvim_augroup('sluice', {
    {'WinScrolled', '*',               'lua require("sluice.commands").update_context()'},
    {'CursorMoved', '*',               'lua require("sluice.commands").update_context()'},
    {'CursorHold',  '*',               'lua require("sluice.commands").update_context()'},
    {'CursorHoldI', '*',               'lua require("sluice.commands").update_context()'},
    {'BufEnter',    '*',               'lua require("sluice.commands").update_context()'},
    {'WinEnter',    '*',               'lua require("sluice.commands").update_context()'},
    {'WinLeave',    '*',               'lua require("sluice.commands").close()'},
    -- {'BufLeave',    '*',               'lua require("sluice").close()'},
    -- {'TabLeave',    '*',               'lua require("sluice").close()'},
    -- {'BufWinLeave',    '*',               'lua require("sluice").close()'},
    {'VimResized',  '*',               'lua require("sluice.commands").open()'},
    {'User',        'SessionSavePre',  'lua require("sluice.commands").close()'},
    {'User',        'SessionSavePost', 'lua require("sluice.commands").open()'},
  })

  M.update_context()
end

function M.disable()
  nvim_augroup('sluice', {})

  window.disable(bufnr)

  M.close()
end

function M.toggle()
  if winid and M.vim.api.nvim_win_is_valid(winid) then
    M.disable()
  else
    M.enable()
  end
end

return M
