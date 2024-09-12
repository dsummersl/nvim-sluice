local convert = require('sluice.convert')

describe('line_to_gutter_line()', function()
  it('returns the correct line number for visible lines', function()
    assert.are.equal(convert.line_to_gutter_line(1, 100, 50, 25), 1)
    assert.are.equal(convert.line_to_gutter_line(25, 100, 50, 25), 25)
    assert.are.equal(convert.line_to_gutter_line(50, 100, 50, 25), 50)
  end)

  it('returns 0 for lines outside the visible range', function()
    assert.are.equal(convert.line_to_gutter_line(1, 100, 50, 50), 0)
    assert.are.equal(convert.line_to_gutter_line(100, 100, 50, 50), 0)
  end)

  it('handles edge cases', function()
    assert.are.equal(convert.line_to_gutter_line(1, 100, 50, 1), 1)
    assert.are.equal(convert.line_to_gutter_line(100, 100, 50, 100), 50)
  end)
end)

describe('line_to_gutter_line_macro()', function()
  it('converts file lines to gutter lines correctly', function()
    assert.are.equal(convert.line_to_gutter_line_macro(1, 100, 50, 1), 1)
    assert.are.equal(convert.line_to_gutter_line_macro(50, 100, 50, 50), 25)
    assert.are.equal(convert.line_to_gutter_line_macro(100, 100, 50, 100), 50)
  end)

  it('handles edge cases', function()
    assert.are.equal(convert.line_to_gutter_line_macro(1, 1000, 10, 1), 1)
    assert.are.equal(convert.line_to_gutter_line_macro(1000, 1000, 10, 1000), 10)
  end)
end)

local gutter_settings = {
  plugins = { 'viewport' },
  viewport = {
    cursor_hl = 'IncSearch',
  },
  window = {
    width = 1,
    default_gutter_hl = 'SluiceColumn',
  }
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
      }, 60, 42)[1],
      expected)
  end)
end)
