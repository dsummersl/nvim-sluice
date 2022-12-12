local M = {
  vim = vim
}

function M.update(settings, bufnr)
  local pattern = M.vim.fn.getreg('/')
  local current_line = M.vim.fn.getpos('.')[2]

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
      local texthl = "Comment"
      if lnum == current_line then
        texthl = "Error"
      end
      -- TODO settings - read them in.
      table.insert(lines_with_matches, {
        lnum = lnum,
        text = "-",
        texthl = texthl,
        priority = 10,
      })
    end
  end

  return lines_with_matches
end


function M.enable(settings, bufnr)
  -- TODO shouldn't there be a way to make these go away on cursor move
end


function M.disable(settings, bufnr)
end


return M
