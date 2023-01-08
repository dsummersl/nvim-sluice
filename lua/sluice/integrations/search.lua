local M = {
  vim = vim
}

local default_settings = {
  match_hl = "SluiceSearchMatch",
  match_line_hl = "SluiceSearchMatchLine",
}

function M.update(settings, bufnr)
  local pattern = M.vim.fn.getreg('/')
  local current_line = M.vim.fn.getpos('.')[2]
  local update_settings = M.vim.tbl_deep_extend('keep', settings.search or {}, default_settings)

  if pattern == '' or M.vim.v.hlsearch == 0 then
    return {}
  end

  if M.vim.o.ignorecase and not M.vim.o.ignorecase then
    pattern = '\\C' .. pattern
  end

  local lines_with_matches = {}

  local lines = M.vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

  for lnum, line in ipairs(lines) do
    if M.vim.fn.match(line, pattern) ~= -1 then
      local texthl = update_settings.match_hl
      if lnum == current_line then
        texthl = update_settings.match_line_hl
      end
      -- TODO settings - read them in.
      table.insert(lines_with_matches, {
        lnum = lnum,
        text = "-",
        texthl = texthl,
        priority = 10,
        plugin = 'search',
      })
    end
  end

  return lines_with_matches
end


function M.enable(_settings, _bufnr)
  -- TODO shouldn't there be a way to make these go away on cursor move
  if M.vim.fn.hlexists('SluiceSearchMatch') == 0 then
    M.vim.cmd('hi link SluiceSearchMatch Comment')
  end
  if M.vim.fn.hlexists('SluiceSearchMatchLine') == 0 then
    M.vim.cmd('hi link SluiceSearchMatchLine Error')
  end
end


function M.disable(_settings, _bufnr)
end


return M
