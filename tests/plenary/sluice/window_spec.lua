local window = require('sluice.window')

local lines = { {
    linehl = "SluiceViewportVisibleArea",
    lnum = 1,
    priority = 5,
    text = " "
  }, {
    linehl = "SluiceCursor",
    lnum = 2,
    priority = 10,
    text = "-"
  }, {
    linehl = "SluiceViewportVisibleArea",
    lnum = 3,
    priority = 5,
    text = " "
  }, {
    linehl = "SluiceViewportVisibleArea",
    lnum = 4,
    priority = 5,
    text = " "
  }, {
    linehl = "SluiceViewportVisibleArea",
    lnum = 5,
    priority = 5,
    text = " "
  }, {
    linehl = "SluiceViewportVisibleArea",
    priority = 5,
    text = " "
  }, {
    linehl = "SluiceColumn",
    lnum = 7,
    priority = 0,
    text = " "
  }, {
    linehl = "SluiceColumn",
    lnum = 8,
    priority = 0,
    text = " "
  }, {
    linehl = "SluiceColumn",
    -- no lnum
    priority = 0,
    text = " "
  }, {
    linehl = "SluiceColumn",
    lnum = 10,
    priority = 0,
    text = " "
  } }

describe('find_best_match()', function()
  it('picks the highest priority', function()
    assert.are.same(window.find_best_match(lines),
      {
        linehl = "SluiceCursor",
        lnum = 2,
        priority = 10,
        text = "-"
      }
    )
  end)

  it('prioritizes the last highest priority', function()
    assert.are.same(window.find_best_match({unpack(lines, 3, 5)}),
      {
        linehl = "SluiceViewportVisibleArea",
        lnum = 3,
        priority = 5,
        text = " "
      }
    )
  end)

  describe('with a key', function()
    it('still prioritizes by priority', function()
      assert.are.same(window.find_best_match(lines, 'lnum'),
        {
          linehl = "SluiceCursor",
          lnum = 2,
          priority = 10,
          text = "-"
        }
      )
    end)
    it('excludes entries without the key', function()
      assert.are.same(window.find_best_match({unpack(lines, 7, 9)}, 'lnum'),
        {
          linehl = "SluiceColumn",
          lnum = 7,
          priority = 0,
          text = " "
        }
      )
    end)

    it('does not compare non-int key values', function()
      local lines = {
        { linehl = "SluiceColumn"   , text = " ", texthl = "" },
        { linehl = "IncSearch"        , lnum = 7  , priority = 1 , text = " " },
        { linehl = "SluiceViewportVisibleArea", lnum = 8  , priority = 0 , text = " " },
        { linehl = "SluiceViewportVisibleArea", lnum = 9  , priority = 0 , text = " " },
      }
      assert.are.same({
          linehl = "IncSearch",
          lnum = 7,
          priority = 1,
          text = " "
        },
        window.find_best_match(lines, 'linehl')
      )
    end)
  end)
end)
