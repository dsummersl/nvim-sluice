local signs = require('sluice.integrations.signs')
local config = require('sluice.config')

describe("signs integration", function()
  it("should use str_table_fn for group matching", function()
    -- Mock vim functions
    signs.vim = {
      fn = {
        sign_getdefined = function() return {} end,
        sign_getplaced = function(_, opts)
          assert.truthy(type(opts.group) == "function")
          assert.truthy(opts.group("test_group"))
          assert.falsy(opts.group("other_group"))
          return {{signs = {}}}
        end
      },
      tbl_extend = vim.tbl_extend
    }

    -- Test with string group
    local settings = {signs = {group = "test_group"}}
    signs.update(settings, 0)

    -- Test with table group
    settings = {signs = {group = {"test_group", "another_group"}}}
    signs.update(settings, 0)

    -- Test with function group
    settings = {signs = {group = function(g) return g:match("^test") end}}
    signs.update(settings, 0)
  end)

  it("should return correct sign data", function()
    -- Mock vim functions
    signs.vim = {
      fn = {
        sign_getdefined = function()
          return {
            {name = "sign1", texthl = "HL1"},
            {name = "sign2", texthl = "HL2"}
          }
        end,
        sign_getplaced = function()
          return {{signs = {
            {name = "sign1", lnum = 1},
            {name = "sign2", lnum = 2}
          }}}
        end
      },
      tbl_extend = vim.tbl_extend
    }

    local result = signs.update({signs = {group = "*"}}, 0)
    assert.equal(2, #result)
    assert.same({name = "sign1", texthl = "HL1", lnum = 1, plugin = "signs"}, result[1])
    assert.same({name = "sign2", texthl = "HL2", lnum = 2, plugin = "signs"}, result[2])
  end)
end)
