local highlight = require('sluice.highlight')
local convert = require('sluice.convert')

M = {
  vim = vim
}

-- TODO there is a bug in here - sometimes the refresh doesnt't happen in the window buffer and I'm left unable to close vim b/c I'm in that buffer!

--- Add styling to the gutter.
function M.refresh_visible_area(bufnr, ns, lines)
  M.vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for i, v in ipairs(lines) do
    if v["texthl"] ~= "" then
      local line_text_hl = v["linehl"] .. v["texthl"]
      local mode = "cterm"
      if vim.o.termguicolors then
        mode = "gui"
      end
      local line_bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(v["linehl"])), "bg", mode)
      highlight.copy_highlight(v["texthl"], line_text_hl, mode == "gui", line_bg)
      M.vim.api.nvim_buf_add_highlight(bufnr, ns, line_text_hl, i - 1, 0, -1)
    else
      M.vim.api.nvim_buf_add_highlight(bufnr, ns, v["linehl"], i - 1, 0, -1)
    end
  end
end

--- Refresh the content of the gutter.
function M.refresh_buffer(bufnr, lines)
  local win_height = M.vim.api.nvim_win_get_height(0)

  local strings = {}
  for _, v in ipairs(lines) do
    table.insert(strings, v["text"])
  end

  M.vim.api.nvim_buf_set_lines(bufnr, 0, win_height - 1, false, strings)
end

--- Create a gutter.
function M.create_window(gutter)
  local gutter_width = 1
  -- local window_settings = gutter.settings.window
  -- if window_settings ~= nil and window_settings.width ~= nil then
  --   gutter_width = gutter.settings.window.width
  -- end

  local buf_lines = M.vim.api.nvim_buf_line_count(0)
  -- TODO this width actually needs to be smart enough to know the widths of all the gutters to do this dynamically.
  local win_width = M.vim.api.nvim_win_get_width(0) - gutter_width - (gutter.gutter_count - gutter.gutter_index) * gutter_width
  local win_height = M.vim.api.nvim_win_get_height(0)

  if win_height >= buf_lines then
    return false
  end

  if not gutter.winid or not M.vim.api.nvim_win_is_valid(gutter.winid) then
    gutter.parent_winid = M.vim.api.nvim_get_current_win()
    gutter.bufnr = M.vim.api.nvim_create_buf(false, true)
    gutter.winid = M.vim.api.nvim_open_win(gutter.bufnr, false, {
      relative = 'win',
      width = gutter_width,
      height = win_height,
      row = 0,
      col = win_width,
      focusable = false,
      style = 'minimal',
    })
  else
    M.vim.api.nvim_win_set_config(gutter.winid, {
      win = gutter.parent_winid,
      relative = 'win',
      width = gutter_width,
      height = win_height,
      row = 0,
      col = win_width,
    })
  end
end

return M
