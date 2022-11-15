local M = {
  vim = vim
}

function M.update(bufnr)
  local pattern = M.vim.fn.getreg('/')
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
      -- TODO settings - read them in.
      table.insert(lines_with_matches, {
        lnum = lnum,
        text = " ∘",
        texthl = "Comment",
        priority = 10,
      })
    end
  end

  return lines_with_matches
end


function M.enable(bufnr)
end


function M.disable(bufnr)
end


return M
