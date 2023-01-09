local M = { }

M.methods = {
  roman_upper = { 'Ⅰ', 'Ⅱ', 'Ⅲ', 'Ⅳ', 'Ⅴ', 'Ⅵ', 'Ⅶ', 'Ⅷ', 'Ⅸ', 'Ⅹ', '*' },
  roman_lower = { 'ⅰ', 'ⅱ', 'ⅲ', 'ⅳ', 'ⅴ', 'ⅵ', 'ⅶ', 'ⅷ', 'ⅸ', 'ⅹ', '*' },
  circle = { '①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '*' },
  circle_2 = { '⑴', '⑵', '⑶', '⑷', '⑸', '⑹', '⑺', '⑻', '⑼', '*' },
  braille = { '⠂', '⠃', '⠇', '⠧', '⠏', '⠟', '⠿', '⡿', '⣿', '*' },
}

--- Functions that allow showing a value for a count of items in different ways
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
