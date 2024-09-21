local highlight = require('sluice.highlight')
local counters = require('sluice.integrations.counters')

local M = {
  vim = vim,
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
      if not (key ~= nil and match[key] == nil) then
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
    local best_texthl_match = M.find_best_match(matches, "texthl")
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
      local mode = "cterm"
      if vim.o.termguicolors then
        mode = "gui"
      end
      if best_linehl ~= nil then
        local line_bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(best_linehl)), "bg", mode)
        local highlight_name = highlight.copy_highlight(best_texthl, mode == "gui", line_bg)
        M.vim.api.nvim_buf_add_highlight(bufnr, ns, highlight_name, i - 1, 0, -1)
      else
        M.vim.api.nvim_buf_add_highlight(bufnr, ns, best_texthl, i - 1, 0, -1)
      end
    else
      M.vim.api.nvim_buf_add_highlight(bufnr, ns, best_linehl, i - 1, 0, -1)
    end
  end
end

--- Refresh the content of the gutter.
function M.set_gutter_lines(bufnr, lines, count_method, width)
  local win_height = M.vim.api.nvim_win_get_height(0)

  local strings = {}
  for _, matches in ipairs(lines) do
    local text = ' '
    local non_empty_matches = 0
    for _, match in ipairs(matches) do
      if match.text ~= " " then
        non_empty_matches = non_empty_matches + 1
      end
    end
    if count_method ~= nil and non_empty_matches > 1 then
      text = counters.count(non_empty_matches, count_method)
    else
      text = M.find_best_match(matches, "text")['text']
    end

    -- pad text to width
    text = string.rep(' ', width - #text) .. text
    table.insert(strings, text)
  end

  M.vim.api.nvim_buf_set_lines(bufnr, 0, win_height - 1, false, strings)
end

function M.get_gutter_column(gutters, gutter_index, layout)
  local window_width = M.vim.api.nvim_win_get_width and M.vim.api.nvim_win_get_width(0) or
  80                                                                                          -- Default to 80 if function not available
  local column = 0
  local gutter_count = #gutters
  local config = require('sluice.config')

  if layout == 'right' then
    for i = gutter_count, gutter_index, -1 do
      local gutter_settings = config.settings.gutters[i]
      if gutter_settings and gutters[i] and gutters[i].enabled ~= false and gutter_settings.layout == 'right' then
        column = column + gutter_settings.width
      end
    end
    return window_width - column
  else -- 'left' layout
    for i = 1, gutter_index - 1 do
      local gutter_settings = config.settings.gutters[i]
      if gutter_settings and gutters[i] and gutters[i].enabled ~= false and gutter_settings.layout == 'left' then
        column = column + gutter_settings.width
      end
    end
    return column
  end
end

--- Create a gutter.
-- side effect: creates bufnr and ns
function M.create_window(gutters, gutter_index)
  local gutter = gutters[gutter_index]
  local gutter_settings = require('sluice.config').settings.gutters[gutter_index]
  local gutter_width = gutter_settings.width
  local layout = gutter_settings.layout

  local col = M.get_gutter_column(gutters, gutter_index, layout)
  local height = M.vim.api.nvim_win_get_height(0)

  if gutter.bufnr == nil then
    gutter.bufnr = M.vim.api.nvim_create_buf(false, true)
    gutter.ns = M.vim.api.nvim_create_namespace('sluice' .. gutter.bufnr)
  end
  if gutter.winid == nil or M.vim.fn.win_id2win(gutter.winid) == 0 then
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
