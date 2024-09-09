local extmark = require("sluice.integrations.extmark_signs")

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
  it("should return extmarks as signs", function()
    local result = extmark.update({ extmarks = { hl_groups = {} } }, 0)
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
end)
