local function find_definition(definitions, name)
  for _,v in ipairs(definitions) do
    if v["name"] == name then
      return v
    end
  end

  return nil
end

local function line_to_gutter_line(line, buffer_lines, height)
  return math.floor(line / buffer_lines * height) + 1
end

local function get_linehl(line, window_top_gutter_line, window_bottom_gutter_line, cursor_gutter_line)
  local linehl = "SluiceColumn"
  if line == cursor_gutter_line then
    linehl = "SluiceCursor"
  elseif line >= window_top_gutter_line and line <= window_bottom_gutter_line then
    linehl = "SluiceVisibleArea"
  end

  return linehl
end

local function signs_to_lines(definitions, signs, window_top, cursor, buffer_lines, height)
  local lines = {}
  local all_signs = signs["signs"]
  local window_top_gutter_line = line_to_gutter_line(window_top, buffer_lines, height)
  local window_bottom_gutter_line = line_to_gutter_line(window_top + height, buffer_lines, height)
  local cursor_gutter_line = line_to_gutter_line(cursor, buffer_lines, height)

  if  all_signs == nil then
    for line=1,height do
      local linehl = get_linehl(line, window_top_gutter_line, window_bottom_gutter_line, cursor_gutter_line)
      table.insert(lines, { texthl = "", linehl = linehl, text = "  " })
    end
    return lines
  end

  local mappings = {}
  for _,v in ipairs(all_signs) do
    local line = line_to_gutter_line(v["lnum"], buffer_lines, height)
    if mappings[line] == nil then
      mappings[line] = { }
    end

    table.insert(mappings[line], v)
  end

  for line=1,height do
    local linehl = get_linehl(line, window_top_gutter_line, window_bottom_gutter_line, cursor_gutter_line)
    if mappings[line] == nil then
      table.insert(lines, { texthl = "", linehl = linehl, text = "  " })
    else
      local name = mappings[line][1]["name"]
      local definition = find_definition(definitions, name)
      table.insert(lines, { texthl = definition["texthl"], linehl = linehl, text = definition["text"] })
    end
  end
  return lines
end

return {
  signs_to_lines = signs_to_lines
}
