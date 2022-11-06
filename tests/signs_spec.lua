local utils = require('sluice_utils')

local vim_mock = mock({
  api = {
    nvim_exec = function()
      return "exec-id"
    end
  },
  fn = {
    synIDattr = function()
      return ""
    end,
    synIDtrans = function() end,
    hlID = function() end
  }
})
utils.set_vim(vim_mock)

local signs = require('lua/signs')

describe('get_gutter_width()', function()
  it('should get gutter width', function()
    -- TODO eventualy I want this to parse signscolumn and return the correct gutter width
    assert.are.equal(2, signs.get_gutter_width())
  end)
end)
