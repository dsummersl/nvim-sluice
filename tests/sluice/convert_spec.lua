local utils_mock = require('tests/utils_mock')
local convert = require('lua/sluice/convert')

local vim_mock = utils_mock.vim_mock

local sign_getdefined = {
  {
    linehl = "SluiceColumn",
    name = "ALEWarningSign",
    numhl = "",
    text = "W ",
    texthl = "WarnHL"
  },
  {
    linehl = "SluiceColumn",
    name = "GitGutterLineRemoved",
    numhl = "",
    text = "- ",
    texthl = "LineRemovedHL"
  },
  {
    linehl = "SluiceColumn",
    name = "GitGutterLineAdded",
    numhl = "",
    text = "+ ",
    texthl = "LineAddedHL"
  },
}

describe("signs_to_lines()", function()
  it("creates lines without text if there are no signs", function()
    local sign_getplaced = { bufnr = 6 }
    assert.are.same(convert.signs_to_lines(sign_getdefined, sign_getplaced, 1, 1, 100, 10), {
      { texthl = "", linehl = "SluiceCursor", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
    })
  end)

  it("creates lines if there are signs", function()
    local sign_getplaced = { signs = {
      { lnum = 21, id = 1, name = 'GitGutterLineAdded', priority = 10, group = 'gitgutter' },
      { lnum = 33, id = 2, name = 'GitGutterLineRemoved', priority = 10, group = 'gitgutter' },
      { lnum = 78, id = 1000008, name = 'ALEWarningSign', priority = 30, group = 'ale' },
      { lnum = 84, id = 1000009, name = 'ALEWarningSign', priority = 30, group = 'ale' },
    }, bufnr = 6 }

    assert.are.same(convert.signs_to_lines(sign_getdefined, sign_getplaced, 1, 1, 100, 10), {
      { texthl = "", linehl = "SluiceCursor", text = "  " },
      { texthl = "LineAddedHL", linehl = "SluiceColumn", text = "+ " },
      { texthl = "LineRemovedHL", linehl = "SluiceColumn", text = "- " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "WarnHL", linehl = "SluiceColumn", text = "W " },
      { texthl = "WarnHL", linehl = "SluiceColumn", text = "W " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
    })
  end)

  it("combines overlapping lines", function()
    local sign_getplaced = { signs = {
      { lnum = 21, id = 1, name = 'GitGutterLineAdded', priority = 10, group = 'gitgutter' },
      { lnum = 22, id = 1, name = 'GitGutterLineAdded', priority = 10, group = 'gitgutter' },
      { lnum = 23, id = 1, name = 'GitGutterLineAdded', priority = 10, group = 'gitgutter' },
      { lnum = 24, id = 1, name = 'GitGutterLineAdded', priority = 10, group = 'gitgutter' },
    }, bufnr = 6 }

    assert.are.same(convert.signs_to_lines(sign_getdefined, sign_getplaced, 1, 1, 100, 10), {
      { texthl = "", linehl = "SluiceCursor", text = "  " },
      { texthl = "LineAddedHL", linehl = "SluiceColumn", text = "+ " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
      { texthl = "", linehl = "SluiceColumn", text = "  " },
    })
  end)

  it("creates lines for larger groups of signs", function()
    local sign_getplaced = {
      bufnr = 1,
      signs = { {
        group = "gitgutter",
        id = 1,
        lnum = 21,
        name = "GitGutterLineAdded",
        priority = 10
      }, {
        group = "gitgutter",
        id = 2,
        lnum = 33,
        name = "GitGutterLineRemoved",
        priority = 10
      }, {
        group = "ale",
        id = 1000001,
        lnum = 78,
        name = "ALEWarningSign",
        priority = 30
      }, {
        group = "ale",
        id = 1000002,
        lnum = 84,
        name = "ALEWarningSign",
        priority = 30
      }, {
        group = "ale",
        id = 1000003,
        lnum = 91,
        name = "ALEWarningSign",
        priority = 30
      }, {
        group = "gitgutter",
        id = 3,
        lnum = 109,
        name = "GitGutterLineAdded",
        priority = 10
      }, {
        group = "gitgutter",
        id = 4,
        lnum = 110,
        name = "GitGutterLineAdded",
        priority = 10
      }, {
        group = "gitgutter",
        id = 5,
        lnum = 111,
        name = "GitGutterLineAdded",
        priority = 10
      }, {
        group = "gitgutter",
        id = 3,
        lnum = 109,
        name = "GitGutterLineAdded",
        priority = 10
      }, {
        group = "gitgutter",
        id = 4,
        lnum = 110,
        name = "GitGutterLineAdded",
        priority = 10
      }, {
        group = "gitgutter",
        id = 5,
        lnum = 111,
        name = "GitGutterLineAdded",
        priority = 10
      }, {
        group = "gitgutter",
        id = 6,
        lnum = 112,
        name = "GitGutterLineAdded",
        priority = 10
      }, {
        group = "gitgutter",
        id = 7,
        lnum = 113,
        name = "GitGutterLineAdded",
        priority = 10
      }, {
        group = "gitgutter",
        id = 8,
        lnum = 114,
        name = "GitGutterLineAdded",
        priority = 10
      }, {
        group = "gitgutter",
        id = 9,
        lnum = 118,
        name = "ALEWarningSign",
        priority = 30
      }, {
        group = "ale",
        id = 1000004,
        lnum = 119,
        name = "GitGutterLineRemoved",
        priority = 10
      } }
    }

    assert.are.same(convert.signs_to_lines(sign_getdefined, sign_getplaced, 1, 1, 119, 11), {
      { linehl = "SluiceCursor", text = "+ ", texthl = "LineAddedHL" },
      { linehl = "SluiceColumn", text = "  ", texthl = "" },
      { linehl = "SluiceColumn", text = "- ", texthl = "LineRemovedHL" },
      { linehl = "SluiceColumn", text = "  ", texthl = "" },
      { linehl = "SluiceColumn", text = "  ", texthl = "" },
      { linehl = "SluiceColumn", text = "  ", texthl = "" },
      { linehl = "SluiceColumn", text = "W ", texthl = "WarnHL" },
      { linehl = "SluiceColumn", text = "W ", texthl = "WarnHL" },
      { linehl = "SluiceColumn", text = "  ", texthl = "" },
      { linehl = "SluiceColumn", text = "W ", texthl = "WarnHL" },
      { linehl = "SluiceColumn", text = "- ", texthl = "LineRemovedHL" }
    })
  end)
end)
