local highlight = require('sluice.highlight')
local convert = require('sluice.convert')

M = {
  vim = vim,
  logger = {},
}

--- Find the best match, ordered by priority.
-- @param matches List of matches from plugins.
-- @param optional key to prioritize by (beyond priority).
function M.find_best_match(matches, key)
  local best_match = nil
  for _, match in ipairs(matches) do
    if best_match == nil then
      best_match = match
    else
      local compare_by_priority = match.priority ~= nil and best_match.priority ~= nil
      local has_same_priority = compare_by_priority and match.priority == best_match.priority
      local compare_by_key = (
        match[key] ~= nil and
        best_match[key] ~= nil and
        (
          not compare_by_priority or
          has_same_priority
        ))

      if not compare_by_priority and match[key] ~= nil and best_match[key] == nil then
        best_match = match
      elseif compare_by_key then
        if match[key] > best_match[key] then
          best_match = match
        end
      else
        if best_match == nil then
          best_match = match
        elseif best_match.priority == nil then
          best_match = match
        elseif best_match.priority ~= nil and match.priority ~= nil and match.priority > best_match.priority then
          best_match = match
        end
      end
    end
  end

  return best_match
end

--- Add styling to the gutter.
function M.refresh_highlights(bufnr, ns, lines)
  M.vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for i, matches in ipairs(lines) do
    table.insert(M.logger, "<")
    local best_texthl_match = M.find_best_match(matches, "texthl")
    table.insert(M.logger, ">")
    local best_linehl_match = M.find_best_match(matches, "linehl")
    local best_linehl = nil
    local best_texthl = nil
    if best_linehl_match ~= nil then
      best_linehl = best_linehl_match.linehl
    end
    if best_texthl_match ~= nil then
      best_texthl = best_texthl_match.texthl
    end

    if best_texthl ~= nil then
      local line_text_hl = "Sluice" .. best_texthl .. string.format("%02d", i)
      local mode = "cterm"
      if vim.o.termguicolors then
        mode = "gui"
      end
      if best_linehl ~= nil then
        local line_bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(best_linehl)), "bg", mode)
        highlight.copy_highlight(best_texthl, line_text_hl, mode == "gui", line_bg)
        M.vim.api.nvim_buf_add_highlight(bufnr, ns, line_text_hl, i - 1, 0, -1)
      else
        -- TODO something f-ed up here
        M.vim.api.nvim_buf_add_highlight(bufnr, ns, best_texthl, i - 1, 0, -1)
      end
    else
      M.vim.api.nvim_buf_add_highlight(bufnr, ns, best_linehl, i - 1, 0, -1)
    end
  end
end

--- Refresh the content of the gutter.
function M.refresh_buffer(bufnr, lines)
  local win_height = M.vim.api.nvim_win_get_height(0)

  local strings = {}
  for _, matches in ipairs(lines) do
    local best_match = M.find_best_match(matches, "text")
    table.insert(strings, best_match["text"])
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
  local col = M.vim.api.nvim_win_get_width(0) - gutter_width - (gutter.gutter_count - gutter.gutter_index) * gutter_width
  local height = M.vim.api.nvim_win_get_height(0)

  if gutter.bufnr == nil then
    gutter.bufnr = M.vim.api.nvim_create_buf(false, true)
  end
  if gutter.winid == nil then
    gutter.winid = M.vim.api.nvim_open_win(gutter.bufnr, false, {
      relative = 'win',
      width = gutter_width,
      height = height,
      row = 0,
      col = col,
      focusable = false,
      style = 'minimal',
    })
  else
    M.vim.api.nvim_win_set_config(gutter.winid, {
      win = M.vim.api.nvim_get_current_win(),
      relative = 'win',
      width = gutter_width,
      height = height,
      row = 0,
      col = col,
    })
  end
end

return M
