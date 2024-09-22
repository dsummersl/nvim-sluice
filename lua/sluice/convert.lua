local M = {
  vim = vim
}

---Convert a line in the file to the corresponding line in the gutter's window.
---@param line integer The line number in the file
---@param buffer_lines integer The total number of lines in the buffer
---@param height integer The height of the gutter window
---@param top_line_number integer The top line number visible in the window
---@return integer The corresponding line number in the gutter, or 0 if out of range
function M.line_to_gutter_line(line, buffer_lines, height, top_line_number)
  if line < top_line_number or line > top_line_number + height then
    return 0
  end

  return line - top_line_number + 1
end

---Convert a line in the file to the corresponding line in the gutter's window (macro mode).
---This only converts the number relative to the total number of lines in the file.
---@param line integer The line number in the file
---@param buffer_lines integer The total number of lines in the buffer
---@param height integer The height of the gutter window
---@param cursor_position integer The current cursor position (unused in this function)
---@return integer The corresponding line number in the gutter
function M.line_to_gutter_line_macro(line, buffer_lines, height, cursor_position)
  local gutter_line = math.floor(line / buffer_lines * height)
  if gutter_line == 0 then
    return 1
  end

  return gutter_line
end

---Look for a highlight definition.
---@param definitions table[] A list of highlight definitions
---@param name string The name of the highlight to find
---@return table|nil The highlight definition if found, nil otherwise
function M.find_definition(definitions, name)
  for _, v in ipairs(definitions) do
    if v["name"] == name then
      return v
    end
  end

  return nil
end

---Convert a list of lines/styles to a list of gutter lines.
---@param gutter_settings table The settings for the gutter
---@param lines table[] A list of dicts with any keys from :highlight, plus text/line
---@param buffer_lines integer The total number of lines in the buffer
---@param height integer The height of the gutter window
---@param top_line_number integer The top line number visible in the window
---@return table[] A list of dicts (of all plugin entries) for each gutter line
function M.lines_to_gutters(gutter_settings, lines, buffer_lines, height, top_line_number)
  -- ensure that each line of the gutter has a definition.
  local gutter_lines = {}
  for line = 1, height do
    gutter_lines[line] = {{ texthl = "", linehl = gutter_settings.default_gutter_hl, text = " " }}
  end

  -- drop in all the lines provided by an integration.
  for _, line in ipairs(lines) do
    local gutter_line_number = 0
    if gutter_settings.render_method == "macro" then
      gutter_line_number = M.line_to_gutter_line_macro(line['lnum'], buffer_lines, height, top_line_number)
    else
      gutter_line_number = M.line_to_gutter_line(line['lnum'], buffer_lines, height, top_line_number)
    end
    if not (gutter_line_number < 1 or gutter_line_number > height) then
      table.insert(gutter_lines[gutter_line_number], line)
    end
  end

  return gutter_lines
end

---Convert lines to gutter lines based on the current window and buffer state.
---@param gutter_settings table The settings for the gutter
---@param lines table[] A list of lines to convert
---@return table[] A list of gutter lines
function M.lines_to_gutter_lines(gutter_settings, lines)
  local win_height = M.vim.api.nvim_win_get_height(0)
  local buf_lines = M.vim.api.nvim_buf_line_count(0)
  local top_line_number = M.vim.fn.line('w0')

  if win_height >= buf_lines then
    return {}
  end

  return M.lines_to_gutters(gutter_settings, lines, buf_lines, win_height, top_line_number)
end

return M
