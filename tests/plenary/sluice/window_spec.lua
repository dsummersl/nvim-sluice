local gutter = require('sluice.gutter')
local window = require('sluice.window')
local config = require('sluice.config')

local lines = { {
    linehl = "SluiceViewportVisibleArea",
    lnum = 1,
    priority = 5,
    text = " "
  }, {
    linehl = "SluiceViewportCursor",
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
        linehl = "SluiceViewportCursor",
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
          linehl = "SluiceViewportCursor",
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

describe('get_gutter_column()', function()
  local vim_width = vim.api.nvim_win_get_width(0)
  local one_gutter = {
      gutters = {{
        window = {
          width = 3
        }
      }},
    }
    local two_gutters = {
        gutters = {{
          window = {
            width = 3
          }
        }, {
          window = {
            width = 2
          }
        }},
      }

  it('returns the right most column by its order', function()
    local gutters = gutter.init_gutters(config)
    assert.are.same(vim_width - 2, window.get_gutter_column(gutters, 1))
    assert.are.same(vim_width - 1, window.get_gutter_column(gutters, 2))
  end)

  it('would account for a plugin with a custom width', function()
    config.apply_user_settings(one_gutter)
    local gutters = gutter.init_gutters(config)
    assert.are.same(vim_width - 3, window.get_gutter_column(gutters, 1))
  end)

  it('would count multiple gutters', function()
    config.apply_user_settings(two_gutters)
    local gutters = gutter.init_gutters(config)
    assert.are.same(vim_width - 5, window.get_gutter_column(gutters, 1))
    assert.are.same(vim_width - 2, window.get_gutter_column(gutters, 2))
  end)

  it('ignores gutters that are not enabled', function()
    two_gutters.gutters[2].enabled = false
    config.apply_user_settings(two_gutters)
    local gutters = gutter.init_gutters(config)
    assert.are.same(vim_width - 3, window.get_gutter_column(gutters, 1))
  end)
end)
