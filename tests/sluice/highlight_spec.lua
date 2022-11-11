local utils_mock = require('tests/utils_mock')
local highlight = require('lua/sluice/highlight')

local vim_mock = utils_mock.vim_mock

describe("copy_highlight()", function()
  before_each(function()
    highlight.vim = mock(vim_mock)
  end)

  it("creates a new cursor without properties", function()
    highlight.copy_highlight("Cursor", "NewCursor", true, "")

    assert.stub(vim_mock.api.nvim_exec).was.called_with("hi NewCursor guifg=white", false)
    assert.stub(vim_mock.api.nvim_exec).was.called_with("hi NewCursor guibg=NONE gui=NONE", false)
  end)

  it("creates a new cursor without properties", function()
    highlight.copy_highlight("Cursor", "NewCursor", true, "")

    assert.stub(vim_mock.api.nvim_exec).was.called_with("hi NewCursor guibg=NONE gui=NONE", false)
  end)

  it("respects function params background color", function()
    highlight.copy_highlight("Cursor", "NewCursor", true, "Green")

    assert.stub(vim_mock.api.nvim_exec).was.called_with("hi NewCursor guibg=Green gui=NONE", false)
  end)

  it("adds background of source", function()
    highlight.copy_highlight("Cursor", "NewCursor", true, "")

    assert.stub(vim_mock.api.nvim_exec).was.called_with("hi NewCursor guibg=Orange", false)
    assert.stub(vim_mock.api.nvim_exec).was.called_with("hi NewCursor guibg=NONE gui=NONE", false)
  end)

  it("function overrides background of any source", function()
    highlight.copy_highlight("Cursor", "NewCursor", true, "Green")

    assert.stub(vim_mock.api.nvim_exec).was.called_with("hi NewCursor guibg=Green gui=NONE", false)
  end)

  it("includes gui settings of source highlight", function()
    local bold_italic_mock = {
      api = {
        nvim_exec = function()
          return "exec-id"
        end
      },
      fn = {
        synIDattr = function(_id, attrib)
          if attrib == "bold" or attrib == "italic" then
            return "1"
          end
          return ""
        end,
        synIDtrans = function() end,
        hlID = function() end
      }
    }
    highlight.vim = mock(bold_italic_mock)
    highlight.copy_highlight("Cursor", "NewCursor", true, "Green")

    assert.stub(bold_italic_mock.api.nvim_exec).was.called_with("hi NewCursor guibg=Green gui=bold,italic", false)
  end)

  -- TODO nocombine
end)
