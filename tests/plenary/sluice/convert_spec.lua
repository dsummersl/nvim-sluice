local convert = require('sluice.convert')

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
