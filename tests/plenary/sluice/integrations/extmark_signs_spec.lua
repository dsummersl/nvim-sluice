local extmark = require("sluice.integrations.extmark_signs")
local config = require("sluice.config")

extmark.vim = {
  api = {
    nvim_buf_get_extmarks = function()
      return {
        { 1, 4, 0, {
          line_hl_group = "DiagnosticSignWarn",
          ns_id = 57,
          priority = 12,
          right_gravity = true,
          sign_hl_group = "DiagnosticSignWarn",
          sign_text = "A "
        } },
        { 12, 13, 0, {
          invalidate = true,
          ns_id = 23,
          priority = 199,
          right_gravity = true,
          sign_hl_group = "MiniDiffSignAdd",
          sign_text = "B "
        } }
      }
    end
  }
}

describe("update", function()
  it("should return extmarks as signs when hl_groups match", function()
    config.str_table_fn = function(t, s) return t[s] end
    local result = extmark.update({ extmarks = { hl_groups = { DiagnosticSignWarn = true, MiniDiffSignAdd = true } } }, 0)
    assert.is_table(result)
    assert.equals(2, #result)
    assert.same({
      lnum = 5,
      text = "A ",
      texthl = "DiagnosticSignWarn",
      priority = 12,
      plugin = 'extmarks',
    }, result[1])
    assert.same({
      lnum = 14,
      text = "B ",
      texthl = "MiniDiffSignAdd",
      priority = 199,
      plugin = 'extmarks',
    }, result[2])
  end)

  it("should filter extmarks based on hl_groups", function()
    config.str_table_fn = function(t, s) return t[s] end
    local result = extmark.update({ extmarks = { hl_groups = { DiagnosticSignWarn = true } } }, 0)
    assert.is_table(result)
    assert.equals(1, #result)
    assert.same({
      lnum = 5,
      text = "A ",
      texthl = "DiagnosticSignWarn",
      priority = 12,
      plugin = 'extmarks',
    }, result[1])
  end)

  it("should return empty table when no hl_groups match", function()
    config.str_table_fn = function(t, s) return t[s] end
    local result = extmark.update({ extmarks = { hl_groups = { SomeOtherGroup = true } } }, 0)
    assert.is_table(result)
    assert.equals(0, #result)
  end)
end)
