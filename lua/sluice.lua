local vim = vim
local api = vim.api

-- Script variables

local winid = nil
local bufnr = api.nvim_create_buf(false, true)
local ns = api.nvim_create_namespace('nvim-sluice')
local utils = require('sluice_utils')

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
  local gutter_width = get_gutter_width()
  local win_width = api.nvim_win_get_width(0) - gutter_width + 1
  local win_height = api.nvim_win_get_height(0)
  local buf_lines = api.nvim_buf_line_count(0)

  if win_height >= buf_lines then
    return M.close()
  end

  if winid == nil or not api.nvim_win_is_valid(winid) then
    winid = api.nvim_open_win(bufnr, false, {
      relative = 'win',
      width = gutter_width,
      height = win_height,
      row = 0,
      col = win_width - gutter_width + 1,
      focusable = false,
      style = 'minimal',
    })
  else
    api.nvim_win_set_config(winid, {
      win = api.nvim_get_current_win(),
      relative = 'win',
      width = gutter_width,
      height = win_height,
      row = 0,
      col = win_width - gutter_width + 1,
    })
  end

  M.refresh()
end

function M.refresh()
  local win_height = api.nvim_win_get_height(0)
  local buf_lines = api.nvim_buf_line_count(0)
  local get_placed = vim.fn.sign_getplaced('%', { group = '*' })
  local get_defined = vim.fn.sign_getdefined()
  local window_top = vim.fn.line('w0')
  local cursor_position = vim.api.nvim_win_get_cursor(0)
  local lines = utils.signs_to_lines(get_defined, get_placed[1], window_top, cursor_position[1], buf_lines, win_height)


  M.refresh_buffer(lines)
  M.refresh_visible_area(lines)
end

function M.copy_highlight(highlight, new_name, mode, override_bg)
  -- define the new hl
  vim.api.nvim_exec("hi " .. new_name .. " " .. mode .. "bg=" .. override_bg, false)

  local attribs = { "bg", "fg", "sp", "bold", "italic", "reverse", "inverse",
    "standout", "underline", "undercurl", "strikethrough" }

  for _,v in ipairs(attribs) do
    local attrib = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(highlight)), v, mode)
    if attrib ~= "" then
      vim.api.nvim_exec("hi " .. new_name .. " " .. mode .. v .. "=" .. attrib, false)
    end
  end

  -- one more time to override the bg color
  vim.api.nvim_exec("hi " .. new_name .. " " .. mode .. "bg=" .. override_bg, false)
end

function M.refresh_visible_area(lines)
  for i,v in ipairs(lines) do
    if v["texthl"] ~= "" then
      local line_text_hl = v["linehl"] .. v["texthl"]
      local mode = "cterm"
      if vim.o.termguicolors then
        mode = "gui"
      end
      local line_bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(v["linehl"])), "bg", mode)
      M.copy_highlight(v["texthl"], line_text_hl, mode, line_bg)
      api.nvim_buf_add_highlight(bufnr, ns, line_text_hl, i - 1, 0, -1)
    else
      api.nvim_buf_add_highlight(bufnr, ns, v["linehl"], i - 1, 0, -1)
    end
  end
end

function M.refresh_buffer(lines)
  local win_height = api.nvim_win_get_height(0)

  local strings = {}
  for _,v in ipairs(lines) do
    table.insert(strings, v["text"])
  end

  vim.fn.nvim_buf_set_lines(bufnr, 0, win_height - 1, false, strings)
end

function M.enable()
  -- TODO buftype nofile -- don't open
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
