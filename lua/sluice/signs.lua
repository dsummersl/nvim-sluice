local xxh32 = require("sluice.luaxxhash")
local utils = require('sluice.sluice_utils')
local vim = utils.get_vim()
local api = vim.api

local M = {}

function M.get_gutter_width ()
  return 2
end


function M.signs_changed(bufnr)
  local get_defined = vim.fn.sign_getdefined()
  local new_hash = xxh32(vim.inspect(get_defined))

  local _, old_hash = pcall(api.nvim_buf_get_var, bufnr, 'sluice_last_defined')

  if new_hash == old_hash then
    return false, get_defined
  end

  api.nvim_buf_set_var(bufnr, 'sluice_last_defined', new_hash)

  return true, get_defined
end

--- Reach the signs, and return a list of lines.
function M.get_signs_to_lines(bufnr)
  local _, get_defined = M.signs_changed(bufnr)

  local win_height = api.nvim_win_get_height(0)
  local buf_lines = api.nvim_buf_line_count(0)

  if win_height >= buf_lines then
    return false
  end

  local get_placed = vim.fn.sign_getplaced('%', { group = '*' })
  local window_top = vim.fn.line('w0')
  local cursor_position = api.nvim_win_get_cursor(0)

  return utils.signs_to_lines(get_defined, get_placed[1], window_top, cursor_position[1], buf_lines, win_height)
end


return M
