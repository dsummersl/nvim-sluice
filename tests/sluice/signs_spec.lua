local utils_mock = require('tests/utils_mock')
local signs = require('lua/sluice/signs')
signs.vim = mock(utils_mock.vim_mock)
