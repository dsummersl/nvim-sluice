local M = {
  vim = vim,
}

local function get_linehl(line, window_top_gutter_line, window_bottom_gutter_line, cursor_gutter_line)
  local linehl = "SluiceColumn"
  if line == cursor_gutter_line then
    linehl = "SluiceCursor"
  elseif line >= window_top_gutter_line and line <= window_bottom_gutter_line then
    linehl = "SluiceVisibleArea"
  end

  return linehl
end

-- mode == gui or cterm boolean
local function copy_highlight(highlight, new_name, is_gui_mode, override_bg)
  local mode = "cterm"
  if is_gui_mode then
    mode = "gui"
  end

  -- define the new hl
  M.vim.api.nvim_exec("hi " .. new_name .. " " .. mode .. "fg=white", false)

  local cterms = { "bold", "italic", "reverse", "inverse", "standout", "underline", "undercurl",
    "strikethrough" }
  local attribs = { "bg", "fg", "sp" }

  for _, v in ipairs(attribs) do
    local attrib = M.vim.fn.synIDattr(M.vim.fn.synIDtrans(M.vim.fn.hlID(highlight)), v, mode)
    if attrib ~= "" then
      M.vim.api.nvim_exec("hi " .. new_name .. " " .. mode .. v .. "=" .. attrib, false)
    end
  end

  local cterm_attribs = {}
  for _, v in ipairs(cterms) do
    local attrib = M.vim.fn.synIDattr(M.vim.fn.synIDtrans(M.vim.fn.hlID(highlight)), v, mode)
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
  M.vim.api.nvim_exec("hi " .. new_name .. " " .. mode .. "bg=" .. override_bg .. " " .. cterm_vals, false)
end

M.copy_highlight = copy_highlight
M.get_linehl = get_linehl

return M
