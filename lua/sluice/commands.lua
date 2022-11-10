local M = {
  vim = vim
}

local config = require('sluice.config')
local winid = nil
local bufnr = M.vim.api.nvim_create_buf(false, true)
local ns = M.vim.api.nvim_create_namespace('nvim-sluice')
local utils = require('sluice.sluice_utils')
local signs = require('sluice.signs')

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

-- Exports

function M.update_context()
  if M.vim.fn.getwinvar(0, '&buftype') ~= '' then return M.close() end
  if M.vim.fn.getwinvar(0, '&previewwindow') ~= 0 then return M.close() end
  if M.vim.fn.getwinvar(0, '&diff') ~= 0 then return M.close() end

  M.open()

  return { winid }
end

function M.close()
  if winid and M.vim.api.nvim_win_is_valid(winid) then
    -- Can't close other windows when the command-line window is open
    if M.vim.api.nvim_call_function('getcmdwintype', {}) ~= '' then
      return
    end

    M.vim.api.nvim_win_close(winid, true)
  end
  winid = nil
end

function M.should_throttle()
  -- TODO ideally this should be a 'tail' throttle rather than a leading edge
  -- type throttle...where an async call is made at the end of the 'throttle_ms' time period.
  local var_exists, last_update_str = pcall(M.vim.api.nvim_buf_get_var, bufnr, 'sluice_last_update')
  local reltime = vim.fn.reltime()

  if not var_exists then
    M.vim.api.nvim_buf_set_var(bufnr, 'sluice_last_update', tostring(reltime[1]) .. " " .. tostring(reltime[2]))
    return false
  end

  local last_update = vim.tbl_map(tonumber, vim.split(last_update_str, " "))

  local should_throttle = vim.fn.reltimefloat(vim.fn.reltime(last_update)) * 1000 < config.settings.throttle_ms

  if not should_throttle then
    M.vim.api.nvim_buf_set_var(bufnr, 'sluice_last_update', tostring(reltime[1]) .. " " .. tostring(reltime[2]))
  end

  return should_throttle
end

--- Create the sluice gutter.
function M.create_sluice(bufnr)
  local buf_lines = M.vim.api.nvim_buf_line_count(0)
  local gutter_width = signs.get_gutter_width()
  local win_width = M.vim.api.nvim_win_get_width(0) - gutter_width + 1
  local win_height = M.vim.api.nvim_win_get_height(0)

  if win_height >= buf_lines then
    return false
  end

  if not winid or not M.vim.api.nvim_win_is_valid(winid) then
    winid = M.vim.api.nvim_open_win(bufnr, false, {
      relative = 'win',
      width = gutter_width,
      height = win_height,
      row = 0,
      col = win_width - gutter_width + 1,
      focusable = false,
      style = 'minimal',
    })
  else
    M.vim.api.nvim_win_set_config(winid, {
      win = M.vim.api.nvim_get_current_win(),
      relative = 'win',
      width = gutter_width,
      height = win_height,
      row = 0,
      col = win_width - gutter_width + 1,
    })
  end
end

function M.open()
  if not M.vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  if M.should_throttle() then
    return
  end

  M.create_sluice(bufnr)

  local lines = signs.get_signs_to_lines(bufnr)
  if not lines then
    M.close()
    return
  end
  -- TODO need to cache 'lines'

  M.refresh_buffer(lines)
  M.refresh_visible_area(lines)
end

function M.refresh_visible_area(lines)
  M.vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for i,v in ipairs(lines) do
    if v["texthl"] ~= "" then
      local line_text_hl = v["linehl"] .. v["texthl"]
      local mode = "cterm"
      if vim.o.termguicolors then
        mode = "gui"
      end
      local line_bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(v["linehl"])), "bg", mode)
      utils.copy_highlight(v["texthl"], line_text_hl, mode == "gui", line_bg)
      M.vim.api.nvim_buf_add_highlight(bufnr, ns, line_text_hl, i - 1, 0, -1)
    else
      M.vim.api.nvim_buf_add_highlight(bufnr, ns, v["linehl"], i - 1, 0, -1)
    end
  end
end

function M.refresh_buffer(lines)
  local win_height = M.vim.api.nvim_win_get_height(0)

  local strings = {}
  for _,v in ipairs(lines) do
    table.insert(strings, v["text"])
  end

  M.vim.api.nvim_buf_set_lines(bufnr, 0, win_height - 1, false, strings)
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

  -- delete any highlights.
  local lines = signs.get_signs_to_lines(bufnr)
  if not lines then
    for _,v in ipairs(lines) do
      if v["texthl"] == "" then
        local line_text_hl = v["linehl"] .. v["texthl"]
        M.vim.api.nvim_exec("hi clear " .. line_text_hl, false)
      end
    end
  end

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
