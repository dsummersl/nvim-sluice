local signs = require('sluice.integrations.signs')

-- Mock vim functions
signs.vim = {
  fn = {
    sign_getdefined = function()
      return {
        { name = "sign1", texthl = "HL1" },
        { name = "sign2", texthl = "HL2" }
      }
    end,
    sign_getplaced = function()
      return { {
        signs = {
          { name = "sign1", lnum = 1 },
          { name = "sign2", lnum = 2 }
        }
      } }
    end
  },
  tbl_extend = vim.tbl_extend,
  tbl_deep_extend = vim.tbl_deep_extend
}

describe("signs update() integration", function()
  it("should return correct sign data without config data", function()
    local result = signs.update({}, 0)
    assert.equal(2, #result)
    assert.same({ name = "sign1", texthl = "HL1", lnum = 1, plugin = "signs" }, result[1])
    assert.same({ name = "sign2", texthl = "HL2", lnum = 2, plugin = "signs" }, result[2])
  end)

  it("should return correct sign data if filtered by settings", function()
    local result = signs.update({ group = "sign1" }, 0)
    assert.equal(1, #result)
    assert.same({ name = "sign1", texthl = "HL1", lnum = 1, plugin = "signs" }, result[1])
  end)
end)
