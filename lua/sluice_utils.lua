local vim = vim



local function set_vim(new_vim)
  vim = new_vim
end

local function get_vim()
  return vim
end

local function find_definition(definitions, name)
  for _,v in ipairs(definitions) do
    if v["name"] == name then
      return v
    end
  end

  return nil
end

local function line_to_gutter_line(line, buffer_lines, height)
  local gutter_line = math.floor(line / buffer_lines * height)
  if gutter_line == 0 then
    return 1
  end

  return gutter_line
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
      local max = mappings[line][1]
      for _,v in ipairs(mappings[line]) do
        if v["priority"] > max["priority"] then
          max = v
        end
      end
      local name = max["name"]
      local definition = find_definition(definitions, name)
      table.insert(lines, { texthl = definition["texthl"], linehl = linehl, text = definition["text"] })
    end
  end
  return lines
end

-- mode == gui or cterm boolean
local function copy_highlight(highlight, new_name, is_gui_mode, override_bg)
  local mode = "cterm"
  if is_gui_mode then
    mode = "gui"
  end

  -- define the new hl
  get_vim().api.nvim_exec("hi " .. new_name .. " " .. mode .. "fg=white", false)

  local cterms = { "bold", "italic", "reverse", "inverse", "standout", "underline", "undercurl",
    "strikethrough" }
  local attribs = { "bg", "fg", "sp" }

  for _,v in ipairs(attribs) do
    local attrib = get_vim().fn.synIDattr(get_vim().fn.synIDtrans(get_vim().fn.hlID(highlight)), v, mode)
    if attrib ~= "" then
      get_vim().api.nvim_exec("hi " .. new_name .. " " .. mode .. v .. "=" .. attrib, false)
    end
  end

  local cterm_attribs = {}
  for _,v in ipairs(cterms) do
    local attrib = get_vim().fn.synIDattr(get_vim().fn.synIDtrans(get_vim().fn.hlID(highlight)), v, mode)
    if attrib ~= "" then
      table.insert(cterm_attribs, v)
    end
  end

  -- one more time to override the bg color
  if override_bg == "" then
    override_bg = 'NONE'
  end

  local cterm_vals = mode .. "=NONE"
  if #cterm_attribs > 0 then
    cterm_vals = mode .. "=" .. table.concat(cterm_attribs, ",")
  end
  get_vim().api.nvim_exec("hi " .. new_name .. " " .. mode .. "bg=" .. override_bg .. " " .. cterm_vals, false)
end

return {
  signs_to_lines = signs_to_lines,
  copy_highlight = copy_highlight,
  set_vim = set_vim,
  get_vim = get_vim,
}
