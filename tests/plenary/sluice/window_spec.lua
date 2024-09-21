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

describe('create_window()', function()
  local mock_vim = {
    api = {
      nvim_create_buf = function() return 1 end,
      nvim_create_namespace = function() return 1 end,
      nvim_open_win = function() return 1 end,
      nvim_win_set_config = function() end,
      nvim_win_get_height = function() return 10 end,
      nvim_win_get_width = function() return 80 end,
      nvim_get_current_win = function() return 0 end,
    },
    fn = {
      win_id2win = function() return 0 end,
    },
    -- Remove spy object
  }

  before_each(function()
    window.vim = mock_vim
    package.loaded['sluice.config'] = nil
    config = require('sluice.config')
    config.settings = {
      gutters = {
        {
          width = 2,
          layout = 'right',
        },
      },
    }
  end)

  it('creates a window with right layout', function()
    local gutters = {{}}
    local called_with = nil
    mock_vim.api.nvim_open_win = function(...)
      called_with = {...}
      return 1
    end
    window.create_window(gutters, 1)
    assert.are.same({1, false, {
      relative = 'win',
      width = 2,
      height = 10,
      row = 0,
      col = mock_vim.api.nvim_win_get_width(0) - 2,
      focusable = false,
      style = 'minimal',
    }}, called_with)
  end)

  it('creates a window with left layout', function()
    config.settings.gutters[1].layout = 'left'
    local gutters = {{}}
    local called_with = nil
    mock_vim.api.nvim_open_win = function(...)
      called_with = {...}
      return 1
    end
    window.create_window(gutters, 1)
    assert.are.same({1, false, {
      relative = 'win',
      width = 2,
      height = 10,
      row = 0,
      col = 0,
      focusable = false,
      style = 'minimal',
    }}, called_with)
  end)

  it('updates an existing window', function()
    local gutters = {{winid = 1}}
    mock_vim.fn.win_id2win = function() return 1 end
    local called_with = nil
    mock_vim.api.nvim_win_set_config = function(...)
      called_with = {...}
    end
    window.create_window(gutters, 1)
    assert.are.same({1, {
      win = 0,
      relative = 'win',
      width = 2,
      height = 10,
      row = 0,
      col = mock_vim.api.nvim_win_get_width(0) - 2,
    }}, called_with)
  end)
end)

describe('get_gutter_column()', function()
  local vim_width = vim.api.nvim_win_get_width(0)
  local one_gutter = {
      gutters = {{
        width = 3,
        layout = 'right'
      }},
    }
    local two_gutters = {
        gutters = {{
          width = 3,
          layout = 'right'
        }, {
          width = 2,
          layout = 'right'
        }},
      }
    local mixed_gutters = {
        gutters = {{
          width = 3,
          layout = 'right'
        }, {
          width = 2,
          layout = 'left'
        }, {
          width = 1,
          layout = 'right'
        }},
      }

  it('would account for a plugin with a custom width', function()
    config.apply_user_settings(one_gutter)
    local gutters = gutter.init_gutters(config)
    assert.are.same(vim_width - 3, window.get_gutter_column(gutters, 1, 'right'))
  end)

  it('would count multiple gutters with the same layout', function()
    config.apply_user_settings(two_gutters)
    local gutters = gutter.init_gutters(config)
    assert.are.same(vim_width - 5, window.get_gutter_column(gutters, 1, 'right'))
    assert.are.same(vim_width - 2, window.get_gutter_column(gutters, 2, 'right'))
  end)

  it('ignores gutters that are not enabled', function()
    two_gutters.gutters[2].enabled = false
    config.apply_user_settings(two_gutters)
    local gutters = gutter.init_gutters(config)
    assert.are.same(vim_width - 3, window.get_gutter_column(gutters, 1, 'right'))
  end)

  it('handles mixed layouts correctly', function()
    config.apply_user_settings(mixed_gutters)
    local gutters = gutter.init_gutters(config)
    assert.are.same(vim_width - 4, window.get_gutter_column(gutters, 1, 'right'))
    assert.are.same(0, window.get_gutter_column(gutters, 2, 'left'))
    assert.are.same(vim_width - 1, window.get_gutter_column(gutters, 3, 'right'))
  end)
end)
