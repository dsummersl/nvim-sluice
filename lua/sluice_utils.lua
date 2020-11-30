-- nvim_buf_line_count
local function signs_to_lines(signs, buffer_lines, height)
  local lines = {}
  local all_signs = signs["signs"]

  if  all_signs == nil then
    for _=1,height do
      table.insert(lines, "")
    end
    return lines
  end

  local mappings = {}
  for _,v in ipairs(all_signs) do
    local line = math.floor(v["lnum"] / buffer_lines * height)
    if mappings[line] == nil then
      mappings[line] = { }
    end

    table.insert(mappings[line], v)
  end

  for line=1,height do
    if mappings[line] == nil then
      table.insert(lines, "")
    else
      table.insert(lines, mappings[line][1]["name"])
    end
  end
  return lines
end

return {
  signs_to_lines = signs_to_lines
}
