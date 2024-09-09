local assert = require("luassert")
local mock = require("luassert.mock")
local extmark = require("sluice.integrations.extmark_signs")

describe("extmark integration", function()
  local bufnr = 1
  local settings = {
    extmarks = {
      hl_groups = {"Error", "Warning", "Info"}
    }
  }

  local function create_mock_extmarks()
    return {
      {1, 0, 0, {sign_hl_group = "Error", sign_text = "E", priority = 10}},
      {2, 1, 0, {sign_hl_group = "Warning", sign_text = "W", priority = 5}},
      {3, 2, 0, {sign_hl_group = "Info", sign_text = "I", priority = 1}},
      {4, 3, 0, {sign_hl_group = "", sign_text = "", priority = 0}},  -- Should be ignored
    }
  end

  before_each(function()
    extmark.vim = mock(vim, true)
  end)

  after_each(function()
    mock.revert(extmark.vim)
  end)

  describe("update", function()
    it("should return extmarks as signs", function()
      extmark.vim.api.nvim_buf_get_extmarks.returns(create_mock_extmarks())

      local result = extmark.update(settings, bufnr)

      assert.is_table(result)
      assert.equals(3, #result)
      assert.same({
        lnum = 1,
        text = "E",
        texthl = "Error",
        priority = 10,
        plugin = 'extmarks',
      }, result[1])
      assert.same({
        lnum = 2,
        text = "W",
        texthl = "Warning",
        priority = 5,
        plugin = 'extmarks',
      }, result[2])
      assert.same({
        lnum = 3,
        text = "I",
        texthl = "Info",
        priority = 1,
        plugin = 'extmarks',
      }, result[3])
    end)

    it("should return empty table when no hl_groups", function()
      local settings_without_hl = {extmarks = {}}
      local result = extmark.update(settings_without_hl, bufnr)
      assert.is_table(result)
      assert.same({}, result)
    end)
  end)

  describe("enable", function()
    it("should not throw an error", function()
      assert.has_no.errors(function()
        extmark.enable(settings, bufnr)
      end)
    end)
  end)

  describe("disable", function()
    it("should clear highlight groups", function()
      extmark.vim.api.nvim_buf_get_extmarks.returns(create_mock_extmarks())
      extmark.disable(settings, bufnr)
      assert.stub(extmark.vim.api.nvim_exec).was.called(3)
      assert.stub(extmark.vim.api.nvim_exec).was.called_with("hi clear Error", false)
      assert.stub(extmark.vim.api.nvim_exec).was.called_with("hi clear Warning", false)
      assert.stub(extmark.vim.api.nvim_exec).was.called_with("hi clear Info", false)
    end)
  end)
end)
