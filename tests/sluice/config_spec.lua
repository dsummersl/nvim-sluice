local utils_mock = require('tests/utils_mock')
local config = require("sluice.config")
config.vim = mock(utils_mock.vim_mock)

describe("apply_user_settings", function()
  it("should apply user settings", function()
    config.apply_user_settings({enable = false})
    assert.are.same(config.settings.enable, false)
  end)
end)