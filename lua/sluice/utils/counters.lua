local M = { }

M.methods = {
  roman_lower = { 'ⅰ', 'ⅱ', 'ⅲ', 'ⅳ', 'ⅴ', 'ⅵ', 'ⅶ', 'ⅷ', 'ⅸ', 'ⅹ', 'ⅺ', 'ⅻ', '∞' },
  roman_upper = { 'Ⅰ', 'Ⅱ', 'Ⅲ', 'Ⅳ', 'Ⅴ', 'Ⅵ', 'Ⅶ', 'Ⅷ', 'Ⅸ', 'Ⅹ', 'Ⅺ', 'Ⅻ', '∞' },
  circle = { '①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⑩', '⑪', '⑫', '⑬', '⑭', '⑮', '⑯', '⑰', '⑱', '⑲', '⑳', '∞' },
  circle_2 = { '⑴', '⑵', '⑶', '⑷', '⑸', '⑹', '⑺', '⑻', '⑼', '⑽', '⑾', '⑿', '⒀', '⒁', '⒂', '⒃', '⒄', '⒅', '⒆', '⒇', '∞' },
  braille = { '⠂', '⠃', '⠇', '⠧', '⠏', '⠟', '⠿', '⡿', '⣿', '*' },
  -- TODO it'd be ideal if these actually represented the % of the screen that the lines represent, rather than just their count
  horizontal_block = { '▁', '▁', '▂', '▂', '▃', '▃', '▄', '▄', '▅', '▅', '▆', '▆', '▇', '▇', '█' },
  vertical_block = { '▏', '▏', '▎', '▎', '▍', '▍', '▌', '▌', '▋', '▋', '▊', '▊', '▉', '▉', '█' },
}

--- Functions that allow showing a value for a count of items in different ways
--- @param number number
--- @param method table
function M.count(number, method)
  if number <= 0 then
    return ' '
  end

  local max = #method
  if number >= max then
    return method[max]
  end

  return method[number]
end

return M
