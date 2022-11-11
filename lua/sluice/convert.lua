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

function M.signs_to_lines(definitions, signs, window_top, cursor, buffer_lines, height)
  local lines = {}
  local all_signs = signs["signs"]
  local window_top_gutter_line = M.line_to_gutter_line(window_top, buffer_lines, height)
  local window_bottom_gutter_line = M.line_to_gutter_line(window_top + height, buffer_lines, height)
  local cursor_gutter_line = M.line_to_gutter_line(cursor, buffer_lines, height)

  if all_signs == nil then
    for line = 1, height do
      local linehl = highlight.get_linehl(line, window_top_gutter_line, window_bottom_gutter_line, cursor_gutter_line)
      table.insert(lines, { texthl = "", linehl = linehl, text = "  " })
    end
    return lines
  end

  local mappings = {}
  for _, v in ipairs(all_signs) do
    local line = M.line_to_gutter_line(v["lnum"], buffer_lines, height)
    if mappings[line] == nil then
      mappings[line] = {}
    end

    table.insert(mappings[line], v)
  end

  for line = 1, height do
    local linehl = highlight.get_linehl(line, window_top_gutter_line, window_bottom_gutter_line, cursor_gutter_line)
    if mappings[line] == nil then
      table.insert(lines, { texthl = "", linehl = linehl, text = "  " })
    else
      local max = mappings[line][1]
      for _, v in ipairs(mappings[line]) do
        if v["priority"] > max["priority"] then
          max = v
        end
      end
      local name = max["name"]
      local definition = M.find_definition(definitions, name)
      if definition ~= nil then
        table.insert(lines, { texthl = definition["texthl"], linehl = linehl, text = definition["text"] })
      end
    end
  end
  return lines
end

--- Reach the signs, and return a list of lines.
function M.lines_to_gutter_lines(lines)
  local win_height = M.vim.api.nvim_win_get_height(0)
  local buf_lines = M.vim.api.nvim_buf_line_count(0)

  if win_height >= buf_lines then
    return false
  end

  local get_placed = M.vim.fn.sign_getplaced('%', { group = '*' })
  local window_top = M.vim.fn.line('w0')
  local cursor_position = M.vim.api.nvim_win_get_cursor(0)

  return M.signs_to_lines(lines, get_placed[1], window_top, cursor_position[1], buf_lines, win_height)
end

return M
