local xxh32 = require("luaxxhash")
local vim = vim
local api = vim.api

-- Script variables

local throttle_ms = 200
local winid = nil
local bufnr = api.nvim_create_buf(false, true)
local ns = api.nvim_create_namespace('nvim-sluice')
local utils = require('sluice_utils')

local get_gutter_width = function()
  return 2
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
  if vim.fn.getwinvar(0, '&buftype') ~= '' then return M.close() end
  if vim.fn.getwinvar(0, '&previewwindow') ~= 0 then return M.close() end
  if vim.fn.getwinvar(0, '&diff') ~= 0 then return M.close() end

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

function M.should_throttle()
  -- TODO ideally this should be a 'tail' throttle rather than a leading edge
  -- type throttle...where an async call is made at the end of the 'throttle_ms' time period.
  local var_exists, last_update_str = pcall(vim.api.nvim_buf_get_var, bufnr, 'sluice_last_update')
  local reltime = vim.fn.reltime()

  if not var_exists then
    vim.api.nvim_buf_set_var(bufnr, 'sluice_last_update', tostring(reltime[1]) .. " " .. tostring(reltime[2]))
    return false
  end

  local last_update = vim.tbl_map(tonumber, vim.split(last_update_str, " "))

  local should_throttle = vim.fn.reltimefloat(vim.fn.reltime(last_update)) * 1000 < throttle_ms

  if not should_throttle then
    vim.api.nvim_buf_set_var(bufnr, 'sluice_last_update', tostring(reltime[1]) .. " " .. tostring(reltime[2]))
  end

  return should_throttle
end

function M.signs_changed()
  local get_defined = vim.fn.sign_getdefined()
  local new_hash = xxh32(vim.inspect(get_defined))

  local _, old_hash = pcall(vim.api.nvim_buf_get_var, bufnr, 'sluice_last_defined')

  if new_hash == old_hash then
    return false, get_defined
  end

  vim.api.nvim_buf_set_var(bufnr, 'sluice_last_defined', new_hash)

  return true, get_defined
end

function M.open()
  if M.should_throttle() then
    return
  end

  local _, get_defined = M.signs_changed()

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

  local get_placed = vim.fn.sign_getplaced('%', { group = '*' })
  local window_top = vim.fn.line('w0')
  local cursor_position = vim.api.nvim_win_get_cursor(0)
  local lines = utils.signs_to_lines(get_defined, get_placed[1], window_top, cursor_position[1], buf_lines, win_height)
  -- TODO need to cache 'lines'

  M.refresh_buffer(lines)
  M.refresh_visible_area(lines)
end

function M.copy_highlight(highlight, new_name, mode, override_bg)
  -- define the new hl
  vim.api.nvim_exec("hi " .. new_name .. " " .. mode .. "fg=white", false)

  local attribs = { "bg", "fg", "sp", "bold", "italic", "reverse", "inverse",
    "standout", "underline", "undercurl", "strikethrough" }

  for _,v in ipairs(attribs) do
    local attrib = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(highlight)), v, mode)
    if attrib ~= "" then
      vim.api.nvim_exec("hi " .. new_name .. " " .. mode .. v .. "=" .. attrib, false)
    end
  end

  -- one more time to override the bg color
  if override_bg == "" then
    override_bg = 'NONE'
  end
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
  nvim_augroup('sluice', {
    {'WinScrolled', '*',               'lua require("sluice").update_context()'},
    {'CursorMoved', '*',               'lua require("sluice").update_context()'},
    {'CursorHold',  '*',               'lua require("sluice").update_context()'},
    {'CursorHoldI', '*',               'lua require("sluice").update_context()'},
    {'BufEnter',    '*',               'lua require("sluice").update_context()'},
    {'WinEnter',    '*',               'lua require("sluice").update_context()'},
    {'WinLeave',    '*',               'lua require("sluice").close()'},
    {'VimResized',  '*',               'lua require("sluice").open()'},
    {'User',        'SessionSavePre',  'lua require("sluice").close()'},
    {'User',        'SessionSavePost', 'lua require("sluice").open()'},
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
