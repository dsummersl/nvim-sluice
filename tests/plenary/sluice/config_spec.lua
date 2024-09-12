local config = require('sluice.config')

describe('sluice.config', function()
  describe('default_enabled_fn', function()
    before_each(function()
      config.vim = {
        validate = vim.validate,
        deepcopy = vim.deepcopy,
        tbl_deep_extend = vim.tbl_deep_extend
      }
      config.vim.api = {
        nvim_win_get_height = function() return 50 end,
        nvim_buf_line_count = function() return 100 end
      }
      config.vim.fn  = {
        getwinvar = function(_, var)
          if var == '&buftype' then return '' end
          if var == '&previewwindow' then return 0 end
          if var == '&diff' then return 0 end
        end
      }
    end)

    it('should return true when conditions are met', function()
      assert.is_true(config.default_enabled_fn({}))
    end)

    it('should return false if window height is larger than buffer lines', function()
      config.vim.api.nvim_win_get_height = function() return 200 end
      assert.is_false(config.default_enabled_fn({}))
    end)

    it('should return false if buftype is not empty', function()
      config.vim.fn.getwinvar = function(_, var)
        if var == '&buftype' then return 'help' end
        if var == '&previewwindow' then return 0 end
        if var == '&diff' then return 0 end
      end
      assert.is_false(config.default_enabled_fn({}))
    end)

    it('should return false if previewwindow', function()
      config.vim.fn.getwinvar = function(_, var)
        if var == '&buftype' then return '' end
        if var == '&previewwindow' then return 1 end
        if var == '&diff' then return 0 end
      end
      assert.is_false(config.default_enabled_fn({}))
    end)

    it('should return false if diff', function()
      config.vim.fn.getwinvar = function(_, var)
        if var == '&buftype' then return '' end
        if var == '&previewwindow' then return 0 end
        if var == '&diff' then return 1 end
      end
      assert.is_false(config.default_enabled_fn({}))
    end)
  end)

  -- Additional tests for other functions and configurations can be added here

  describe('apply_user_settings', function()
    it('should override default settings with user settings', function()
      local user_settings = {
        enable = false,
        throttle_ms = 200,
        gutters = {
          {
            plugins = { 'viewport', 'counters' },
            window = {
              width = 2,
              enabled_fn = function() return true end,
            },
          },
        },
      }
      config.apply_user_settings(user_settings)
      assert.is_false(config.settings.enable)
      assert.are.equal(200, config.settings.throttle_ms)
      assert.are.equal(2, config.settings.gutters[1].window.width)
      assert.is_true(config.settings.gutters[1].window.enabled_fn())
    end)

    it('should not override unspecified settings', function()
      config.apply_user_settings({})
      assert.is_true(config.settings.enable)
      -- Check that other settings are still at their default values
      assert.are.equal(150, config.settings.throttle_ms)
      assert.are.equal('viewport', config.settings.gutters[1].plugins[1])
    end)

    it('should handle nil user settings', function()
      config.apply_user_settings(nil)
      -- Check that settings are still at their default values
      assert.is_true(config.settings.enable)
      assert.are.equal(150, config.settings.throttle_ms)
      assert.are.equal('viewport', config.settings.gutters[1].plugins[1])
    end)

    it('should throw an error for invalid types', function()
      assert.has_error(function()
        config.apply_user_settings({ enable = 'true' })
      end, "enable: expected boolean, got string")

      assert.has_error(function()
        config.apply_user_settings({ throttle_ms = '200' })
      end, "throttle_ms: expected number, got string")

      assert.has_error(function()
        config.apply_user_settings({ gutters = 'not a table' })
      end, "gutters: expected table, got string")

      assert.has_error(function()
        config.apply_user_settings({ gutters = { { window = { width = 'two' } } } })
      end, "gutters[1].window.width: expected number, got string")
    end)

    it('should handle signs group setting', function()
      local user_settings = {
        gutters = {
          {
            plugins = { 'signs' },
            signs = {
              group = 'custom_group'
            }
          }
        }
      }
      config.apply_user_settings(user_settings)
      assert.are.equal('custom_group', config.settings.gutters[1].signs.group)
    end)

    it('should handle window layout setting', function()
      local user_settings = {
        gutters = {
          {
            plugins = { 'viewport' },
            window = {
              layout = 'left'
            }
          }
        }
      }
      config.apply_user_settings(user_settings)
      assert.are.equal('left', config.settings.gutters[1].window.layout)
    end)

    it('should default to right layout when not specified', function()
      local user_settings = {
        gutters = {
          {
            plugins = { 'viewport' },
            window = {}
          }
        }
      }
      config.apply_user_settings(user_settings)
      assert.are.equal('right', config.settings.gutters[1].window.layout)
    end)

    it('should throw an error for invalid layout', function()
      local user_settings = {
        gutters = {
          {
            plugins = { 'viewport' },
            window = {
              layout = 'invalid'
            }
          }
        }
      }
      assert.has_error(function()
        config.apply_user_settings(user_settings)
      end, "gutters[1].window.layout must be 'left' or 'right'")
    end)

    it('should throw an error for invalid types', function()
      assert.has_error(function()
        config.apply_user_settings({ enable = 'true' })
      end, "enable: expected boolean, got string")

      assert.has_error(function()
        config.apply_user_settings({ throttle_ms = '200' })
      end, "throttle_ms: expected number, got string")

      assert.has_error(function()
        config.apply_user_settings({ gutters = 'not a table' })
      end, "gutters: expected table, got string")

      assert.has_error(function()
        config.apply_user_settings({ gutters = { { window = { width = 'two' } } } })
      end, "gutters[1].window.width: expected number, got string")
    end)

    it('should handle signs group setting', function()
      local user_settings = {
        gutters = {
          {
            plugins = { 'signs' },
            signs = {
              group = 'custom_group'
            }
          }
        }
      }
      config.apply_user_settings(user_settings)
      assert.are.equal('custom_group', config.settings.gutters[1].signs.group)
    end)
  end)

  describe('str_table_fn', function()
    it('should return true for matching strings', function()
      assert.is_true(config.str_table_fn("test", "test"))
    end)

    it('should return false for non-matching strings', function()
      assert.is_false(config.str_table_fn("test", "other"))
    end)

    it('should return true for value in table', function()
      assert.is_true(config.str_table_fn({"a", "b", "c"}, "b"))
    end)

    it('should return false for value not in table', function()
      assert.is_false(config.str_table_fn({"a", "b", "c"}, "d"))
    end)

    it('should return true when function returns true', function()
      assert.is_true(config.str_table_fn(function(x) return x > 5 end, 10))
    end)

    it('should return false when function returns false', function()
      assert.is_false(config.str_table_fn(function(x) return x > 5 end, 3))
    end)

    it('should return false for unsupported types', function()
      assert.is_false(config.str_table_fn(123, "test"))
      assert.is_false(config.str_table_fn(true, "test"))
      assert.is_false(config.str_table_fn(nil, "test"))
    end)
  end)
end)
