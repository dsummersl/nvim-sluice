local M = {
  vim = vim,
  enabled = false
}

local gutter = require('sluice.gutter')

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

function M.update_context()
  -- do nothing for preview/diff/non-bufs
  if M.vim.fn.getwinvar(0, '&buftype') ~= '' then return M.close() end
  if M.vim.fn.getwinvar(0, '&previewwindow') ~= 0 then return M.close() end
  if M.vim.fn.getwinvar(0, '&diff') ~= 0 then return M.close() end

  M.open()
end

function M.close()
  gutter.close()
end

function M.open()
  gutter.open()
end

function M.enable()
  M.enabled = true

  -- TODO move these to the various plugins
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
  M.enabled = false

  nvim_augroup('sluice', {})

  gutter.disable()

  M.close()
end

function M.toggle()
  if M.enabled then
    M.disable()
  else
    M.enable()
  end
end

return M
