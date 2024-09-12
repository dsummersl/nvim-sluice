local M = {
  vim = vim
}

--- Convert a line in the file, to the corresponding line in the gutter's
--- window.
function M.line_to_gutter_line(line, buffer_lines, height, cursor_position)
  return line
end

--- Convert a line in the file, to the corresponding line in the gutter's
--- window. This only converts the number relative to the total number of lines
--- in the file (macro mode)
function M.line_to_gutter_line_macro(line, buffer_lines, height, cursor_position)
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
-- @param lines A list of dicts with any keys from :highlight, plus text/line.
-- @returns A list of dicts (of all plugin entries) for each gutter line.
function M.lines_to_gutters(settings, lines, buffer_lines, height, cursor_position)
  -- ensure that each line of the gutter has a definition.
  local gutter_lines = {}
  for line = 1, height do
    gutter_lines[line] = {{ texthl = "", linehl = settings.window.default_gutter_hl, text = " " }}
  end

  -- drop in all the lines provided by an integration.
  for _, line in ipairs(lines) do
    local gutter_line_number = 0
    if settings.window.render_method == "macro" then
      gutter_line_number = M.line_to_gutter_line_macro(line['lnum'], buffer_lines, height, cursor_position)
    else
      gutter_line_number = M.line_to_gutter_line(line['lnum'], buffer_lines, height, cursor_position)
    end
    if not (gutter_line_number < 1 or gutter_line_number > height) then
      table.insert(gutter_lines[gutter_line_number], line)
    end
  end

  return gutter_lines
end

---
function M.lines_to_gutter_lines(settings, lines)
  local win_height = M.vim.api.nvim_win_get_height(0)
  local buf_lines = M.vim.api.nvim_buf_line_count(0)
  local cursor_position = M.vim.api.nvim_win_get_cursor(0)[1]

  if win_height >= buf_lines then
    return {}
  end

  return M.lines_to_gutters(settings, lines, buf_lines, win_height, cursor_position)
end

return M
