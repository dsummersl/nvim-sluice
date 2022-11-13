local config = require('sluice.config')
local highlight = require('sluice.highlight')
local convert = require('sluice.convert')

M = {
  vim = vim
}

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
function M.create_window(winid, bufnr)
  local buf_lines = M.vim.api.nvim_buf_line_count(0)
  local gutter_width = 2
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

  return winid
end

--- Update the gutter with new lines.
function M.update(gutter_bufnr, ns, lines)
  -- TODO store this plugin and its updated value
  -- TODO then replay all the plugins in order.
  local gutter_lines = convert.lines_to_gutter_lines(lines)
  if not gutter_lines then
    M.close()
    return
  end
  M.refresh_buffer(gutter_bufnr, gutter_lines)
  M.refresh_visible_area(gutter_bufnr, ns, gutter_lines)
end

function M.open(gutter_winid, gutter_bufnr, ns)
  if not M.vim.api.nvim_buf_is_valid(gutter_bufnr) then
    return false
  end

  local new_gutter_winid = M.create_window(gutter_winid, gutter_bufnr)

  local lines = {}
  for _, v in ipairs(config.settings.gutters) do
    local integration = require('sluice.integrations.' .. v.integration)
    local update_fn = integration.enable(M.vim.fn.bufnr())
    local integration_lines = update_fn(M.vim.fn.bufnr())
    for _, v in ipairs(integration_lines) do
      table.insert(lines, v)
    end
  end
  M.update(gutter_bufnr, ns, lines)

  return new_gutter_winid
end

function M.close(gutter_winid)
  if gutter_winid and M.vim.api.nvim_win_is_valid(gutter_winid) then
    -- Can't close other windows when the command-line window is open
    if M.vim.api.nvim_call_function('getcmdwintype', {}) ~= '' then
      return
    end

    M.vim.api.nvim_win_close(gutter_winid, true)
  end
end

function M.disable(gutter_bufnr)
  for _, v in ipairs(config.settings.gutters) do
    local integration = require('sluice.integrations.' .. v.integration)
    integration.disable(gutter_bufnr)
  end
end

return M
