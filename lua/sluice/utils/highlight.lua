local xxhash32 = require('sluice.utils.luaxxhash')

local M = {
  vim = vim,
}

--- Create a new highlight from another.
-- mode == gui or cterm boolean
local function copy_highlight(highlight, is_gui_mode, override_bg)
  local mode = "cterm"
  if is_gui_mode then
    mode = "gui"
  end
  local properties = {}

  local attribs = { "bg", "fg", "sp" }
  for _, v in pairs(attribs) do
    local attrib = M.vim.fn.synIDattr(M.vim.fn.synIDtrans(M.vim.fn.hlID(highlight)), v, mode)
    if attrib ~= "" then
      properties[mode .. v] = attrib
    end
  end

  local cterms = { "bold", "italic", "reverse", "inverse", "standout", "underline", "undercurl",
    "strikethrough" }
  local cterm_attribs = {}
  for _, v in pairs(cterms) do
    local attrib = M.vim.fn.synIDattr(M.vim.fn.synIDtrans(M.vim.fn.hlID(highlight)), v, mode)
    if attrib ~= "" then
      table.insert(cterm_attribs, v)
    end
  end

  if override_bg ~= "" then
    properties[mode .. 'bg'] = override_bg
  end

  local cterm_vals = mode .. "=NONE"
  if #cterm_attribs > 0 then
    cterm_vals = mode .. "=" .. table.concat(cterm_attribs, ",")
  end

  local property_vals = ""
  for k, v in pairs(properties) do
    property_vals = property_vals .. " " .. k .. "=" .. v
  end

  local new_name = "Sluice" .. xxhash32(property_vals .. cterm_vals)
  local highlight_definition = "hi " .. new_name .. property_vals .. " " .. cterm_vals

  -- print("|highlight_definition = " .. M.vim.inspect(highlight_definition))
  M.vim.api.nvim_exec(highlight_definition, false)

  return new_name
end

M.copy_highlight = copy_highlight

return M
