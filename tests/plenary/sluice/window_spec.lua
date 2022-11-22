local window = require('sluice.window')

local lines = { {
    linehl = "SluiceVisibleArea",
    lnum = 1,
    priority = 5,
    text = " "
  }, {
    linehl = "SluiceCursor",
    lnum = 2,
    priority = 10,
    text = "-"
  }, {
    linehl = "SluiceVisibleArea",
    lnum = 3,
    priority = 5,
    text = " "
  }, {
    linehl = "SluiceVisibleArea",
    lnum = 4,
    priority = 5,
    text = " "
  }, {
    linehl = "SluiceVisibleArea",
    lnum = 5,
    priority = 5,
    text = " "
  }, {
    linehl = "SluiceVisibleArea",
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
        linehl = "SluiceVisibleArea",
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
    it('among the same priority it picks the highest lnum', function()
      assert.are.same(window.find_best_match({unpack(lines, 3, 5)}, 'lnum'),
        {
          linehl = "SluiceVisibleArea",
          lnum = 5,
          priority = 5,
          text = " "
        }
      )
    end)
    it('excludes entries without the key', function()
      assert.are.same(window.find_best_match({unpack(lines, 7, 9)}, 'lnum'),
        {
          linehl = "SluiceColumn",
          lnum = 8,
          priority = 0,
          text = " "
        }
      )
    end)
  end)
end)
