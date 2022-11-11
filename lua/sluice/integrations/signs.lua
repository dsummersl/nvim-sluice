local xxh32 = require("sluice.luaxxhash")
local highlight = require('sluice.highlight')

local M = {
  vim = vim
}

local function find_definition(definitions, name)
  for _, v in ipairs(definitions) do
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

local function signs_to_lines(definitions, signs, window_top, cursor, buffer_lines, height)
  local lines = {}
  local all_signs = signs["signs"]
  local window_top_gutter_line = line_to_gutter_line(window_top, buffer_lines, height)
  local window_bottom_gutter_line = line_to_gutter_line(window_top + height, buffer_lines, height)
  local cursor_gutter_line = line_to_gutter_line(cursor, buffer_lines, height)

  if all_signs == nil then
    for line = 1, height do
      local linehl = highlight.get_linehl(line, window_top_gutter_line, window_bottom_gutter_line, cursor_gutter_line)
      table.insert(lines, { texthl = "", linehl = linehl, text = "  " })
    end
    return lines
  end

  local mappings = {}
  for _, v in ipairs(all_signs) do
    local line = line_to_gutter_line(v["lnum"], buffer_lines, height)
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
      local definition = find_definition(definitions, name)
      table.insert(lines, { texthl = definition["texthl"], linehl = linehl, text = definition["text"] })
    end
  end
  return lines
end



--- Returns a table of signs, and whether they have changed since the last call to this method.
function M.signs_changed(bufnr)
  local get_defined = M.vim.fn.sign_getdefined()
  local new_hash = xxh32(M.vim.inspect(get_defined))

  local _, old_hash = pcall(M.vim.api.nvim_buf_get_var, bufnr, 'sluice_last_defined')

  if new_hash == old_hash then
    return false, get_defined
  end

  M.vim.api.nvim_buf_set_var(bufnr, 'sluice_last_defined', new_hash)

  return true, get_defined
end

--- Reach the signs, and return a list of lines.
function M.get_signs_to_lines(bufnr)
  local _, get_defined = M.signs_changed(bufnr)

  local win_height = M.vim.api.nvim_win_get_height(0)
  local buf_lines = M.vim.api.nvim_buf_line_count(0)

  if win_height >= buf_lines then
    return false
  end

  local get_placed = M.vim.fn.sign_getplaced('%', { group = '*' })
  local window_top = M.vim.fn.line('w0')
  local cursor_position = M.vim.api.nvim_win_get_cursor(0)

  return signs_to_lines(get_defined, get_placed[1], window_top, cursor_position[1], buf_lines, win_height)
end

function M.enable(bufnr, ns, update_fn)
  -- TODO for now we just call it directly, but eventually we'd do this for
  update_fn(bufnr, ns, M.get_signs_to_lines(bufnr))
end

function M.disable(bufnr)
  local lines = M.get_signs_to_lines(bufnr)
  if not lines then
    for _,v in ipairs(lines) do
      if v["texthl"] == "" then
        local line_text_hl = v["linehl"] .. v["texthl"]
        M.vim.api.nvim_exec("hi clear " .. line_text_hl, false)
      end
    end
  end
end

return M
