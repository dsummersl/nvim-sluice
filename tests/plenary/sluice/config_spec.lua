local config = require('sluice.config')

describe('sluice.config', function()

  before_each(function()
    -- Reset to default settings before each test
    config.apply_user_settings({})
    -- Mock the vim module in config
    config.vim = {
      api = {
        nvim_win_get_height = function() return 100 end,
        nvim_buf_line_count = function() return 50 end
      },
      fn = {
        getwinvar = function(_, var)
          if var == '&buftype' then return '' end
          if var == '&previewwindow' then return 0 end
          if var == '&diff' then return 0 end
        end
      }
    }
  end)

  describe('default_enabled_fn', function()
    it('should return true when conditions are met', function()
      assert.is_true(config.default_enabled_fn({}))
    end)

    it('should return false when conditions are not met', function()
      -- Mocking the conditions where the gutter should not be enabled
      config.vim.api.nvim_win_get_height = function() return 50 end
      config.vim.api.nvim_buf_line_count = function() return 100 end
      config.vim.fn.getwinvar = function(_, var)
        if var == '&buftype' then return 'nofile' end
        if var == '&previewwindow' then return 1 end
        if var == '&diff' then return 1 end
      end
      assert.is_false(config.default_enabled_fn({}))
    end)
  end)

  -- Additional tests for other functions and configurations can be added here

end)
