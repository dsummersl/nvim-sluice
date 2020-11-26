local vim = vim
local api = vim.api

-- Script variables

local winid = nil
local bufnr = api.nvim_create_buf(false, true)
local ns = api.nvim_create_namespace('nvim-sluice')

local get_gutter_width = function()
  local saved_view = api.nvim_call_function('winsaveview', {})

  api.nvim_call_function('cursor', { 0, 1 })
  local gutter_width = api.nvim_call_function('wincol', {}) - 1

  api.nvim_call_function('winrestview', { saved_view })
  return gutter_width
end

local nvim_augroup = function(group_name, definitions)
  api.nvim_command('augroup ' .. group_name)
  api.nvim_command('autocmd!')
  for _, def in ipairs(definitions) do
    local command = table.concat({'autocmd', unpack(def)}, ' ')
    if api.nvim_call_function('exists', {'##' .. def[1]}) ~= 0 then
      api.nvim_command(command)
    end
  end
  api.nvim_command('augroup END')
end

-- Exports

local M = {}

function M.update_context()
  if api.nvim_get_option('buftype') ~= '' or vim.fn.getwinvar(0, '&previewwindow') ~= 0 then
    M.close()
    return
  end

  M.open()

  return { winid }
end

function M.close()
  if winid ~= nil and api.nvim_win_is_valid(winid) then
    -- Can't close other windows when the command-line window is open
    if api.nvim_call_function('getcmdwintype', {}) ~= '' then
      return
    end

    api.nvim_win_close(winid, true)
  end
  winid = nil
end

function M.open()
  if winid ~= nil and api.nvim_win_is_valid(winid) then
    return
  end

  local gutter_width = get_gutter_width()
  local win_width = api.nvim_win_get_width(0) - gutter_width
  local win_height = api.nvim_win_get_height(0)

  winid = api.nvim_open_win(bufnr, false, {
    relative = 'win',
    width = 2,
    height = win_height,
    row = 0,
    col = win_width,
    focusable = false,
    style = 'minimal',
  })

  -- ▁▂▃▄▅▆▇█
end

function M.enable()
  nvim_augroup('sluice', {
    {'WinScrolled', '*',               'silent lua require("sluice").update_context()'},
    {'CursorMoved', '*',               'silent lua require("sluice").update_context()'},
    {'BufEnter',    '*',               'silent lua require("sluice").update_context()'},
    {'WinEnter',    '*',               'silent lua require("sluice").update_context()'},
    {'WinLeave',    '*',               'silent lua require("sluice").close()'},
    {'VimResized',  '*',               'silent lua require("sluice").open()'},
    {'User',        'SessionSavePre',  'silent lua require("sluice").close()'},
    {'User',        'SessionSavePost', 'silent lua require("sluice").open()'},
  })

  M.update_context()
end

function M.disable()
  nvim_augroup('sluice', {})

  M.close()
end

-- Setup

M.enable()

api.nvim_command('command! SluiceEnable  lua require("sluice").enable()')
api.nvim_command('command! SluiceDisable lua require("sluice").disable()')

return M
