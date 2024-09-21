local convert = require('sluice.convert')

describe('line_to_gutter_line()', function()
  it('returns the correct line number when scrolling', function()
    assert.are.equal(2, convert.line_to_gutter_line(2,  -1, 50, 1))
    assert.are.equal(1, convert.line_to_gutter_line(2,  -1, 50, 2))
    assert.are.equal(0, convert.line_to_gutter_line(2,  -1, 50, 3))
  end)

  it('returns 0 for lines outside the visible range', function()
    assert.are.equal(0, convert.line_to_gutter_line(1,   -1, 50, 50))
    assert.are.equal(0, convert.line_to_gutter_line(101, -1, 50, 50))
  end)
end)

describe('line_to_gutter_line_macro()', function()
  it('converts file lines to gutter lines correctly', function()
    assert.are.equal(convert.line_to_gutter_line_macro(1,   100, 50, 1), 1)
    assert.are.equal(convert.line_to_gutter_line_macro(50,  100, 50, 50), 25)
    assert.are.equal(convert.line_to_gutter_line_macro(100, 100, 50, 100), 50)
  end)

  it('handles edge cases', function()
    assert.are.equal(convert.line_to_gutter_line_macro(1,    1000, 10, 1), 1)
    assert.are.equal(convert.line_to_gutter_line_macro(1000, 1000, 10, 1000), 10)
  end)
end)

local gutter_settings = {
  width = 1,
  default_gutter_hl = 'SluiceColumn',
  plugins = { 'viewport' },
  viewport = {
    cursor_hl = 'IncSearch',
  },
}

describe('lines_to_gutters()', function()
  it('returns filler gutter values if there are no lines', function()
    local expected = {}
    for i = 1, 10, 1 do
      table.insert(expected, {{
        linehl = 'SluiceColumn',
        text = ' ',
        texthl = '',
      }})
    end
    assert.are.same(convert.lines_to_gutters(gutter_settings, {}, 100, 10), expected)
  end)

  it('shows a match on the first line', function()
    local expected = {
      {
        linehl = 'SluiceColumn',
        text = ' ',
        texthl = '',
      },
      {
        linehl = 'SluiceViewportCursor',
        text = ' ',
        lnum = 1,
        priority = 1,
      }
    }
    assert.are.same(
      convert.lines_to_gutters(gutter_settings, {
        {
          linehl = "SluiceViewportCursor",
          lnum = 1,
          priority = 1,
          text = " "
        }
      }, 60, 42, 1)[1],
      expected)
  end)
end)
