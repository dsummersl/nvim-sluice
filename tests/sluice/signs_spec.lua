local utils_mock = require('tests/utils_mock')
local signs = require('lua/sluice/signs')
signs.vim = mock(utils_mock.vim_mock)

describe('get_gutter_width()', function()
  it('should get gutter width', function()
    -- TODO eventually I want this to parse signscolumn and return the correct gutter width
    assert.are.equal(2, signs.get_gutter_width())
  end)
end)
