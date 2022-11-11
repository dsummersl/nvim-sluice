local config = require('sluice.config')
local utils = require('sluice.sluice_utils')
local signs = require('sluice.integrations.signs')

M = {
  vim = vim
}

function M.refresh_visible_area(bufnr, ns, lines)
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

--- Refresh the gutter buffer.
function M.refresh_buffer(bufnr, lines)
  local win_height = M.vim.api.nvim_win_get_height(0)

  local strings = {}
  for _,v in ipairs(lines) do
    table.insert(strings, v["text"])
  end

  M.vim.api.nvim_buf_set_lines(bufnr, 0, win_height - 1, false, strings)
end

--- Create a gutter.
function M.create_window(winid, bufnr)
  local buf_lines = M.vim.api.nvim_buf_line_count(0)
  local gutter_width = config.settings.gutter_width
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

function M.open(winid, bufnr, ns)
  if not M.vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local winid = M.create_window(winid, bufnr)

  -- TODO look into the configuration and setup the integrations that exist.

  local lines = signs.get_signs_to_lines(bufnr)
  if not lines then
    M.close()
    return
  end
  -- TODO need to cache 'lines'

  M.refresh_buffer(bufnr, lines)
  M.refresh_visible_area(bufnr, ns, lines)

  return winid
end

function M.close(winid)
  if winid and M.vim.api.nvim_win_is_valid(winid) then
    -- Can't close other windows when the command-line window is open
    if M.vim.api.nvim_call_function('getcmdwintype', {}) ~= '' then
      return
    end

    M.vim.api.nvim_win_close(winid, true)
  end
end

return M
