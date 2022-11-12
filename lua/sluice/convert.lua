local highlight = require('sluice.highlight')

local M = {
  vim = vim
}

--- Convert a line in the file, to the corresponding line in the gutter.
function M.line_to_gutter_line(line, buffer_lines, height)
  local gutter_line = math.floor(line / buffer_lines * height)
  if gutter_line == 0 then
    return 1
  end

  return gutter_line
end

--- Look for a highlight definition.
function M.find_definition(definitions, name)
  for _, v in ipairs(definitions) do
    if v["name"] == name then
      return v
    end
  end

  return nil
end

--- Convert a list of lines/styles to a list of gutter lines.
-- @param lines A list of dicts with any keys from :highlight, plus text/line/priority.
function M.lines_to_gutters(lines, window_top, cursor, buffer_lines, height)
  local window_top_gutter_line = M.line_to_gutter_line(window_top, buffer_lines, height)
  local window_bottom_gutter_line = M.line_to_gutter_line(window_top + height, buffer_lines, height)
  local cursor_gutter_line = M.line_to_gutter_line(cursor, buffer_lines, height)

  -- ensure that each line of the gutter has a definition.
  local gutter_lines = {}
  for line = 1, height do
    local linehl = highlight.get_linehl(line, window_top_gutter_line, window_bottom_gutter_line, cursor_gutter_line)
    gutter_lines[line] = { texthl = "", linehl = linehl, text = "  ", priority = 0 }
  end

  -- drop in all the lines provided by an integration.
  for _, line in ipairs(lines) do
    local gutter_line_number = M.line_to_gutter_line(line['lnum'], buffer_lines, height)
    local gutter_line = gutter_lines[gutter_line_number]
    if gutter_line["priority"] < line["priority"] then
      gutter_lines[gutter_line_number] = M.vim.tbl_extend('force', gutter_line, line)
    end
  end

  return gutter_lines
end

---
function M.lines_to_gutter_lines(lines)
  local win_height = M.vim.api.nvim_win_get_height(0)
  local buf_lines = M.vim.api.nvim_buf_line_count(0)

  if win_height >= buf_lines then
    return false
  end

  local window_top = M.vim.fn.line('w0')
  local cursor_position = M.vim.api.nvim_win_get_cursor(0)

  return M.lines_to_gutters(lines, window_top, cursor_position[1], buf_lines, win_height)
end

return M
