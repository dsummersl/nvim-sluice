local M = {
  vim = vim
}

function M.update(settings, winid)
  local matchlist = matchlist()
  local bufnr = M.vim.fn.getwininfo(winid)[1]

  local lines_with_matches = {}

  local lines = M.vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

  for lnum, line in pairs(lines) do
    -- Convert to string to handle special buffers (e.g., ex history) that may return Blob objects
    local line_str = tostring(line)
    if M.vim.fn.match(line_str, pattern) ~= -1 then
      table.insert(lines_with_matches, {
        lnum = lnum,
        text = "/ ",
        texthl = "Comment",
        priority = 10,
        plugin = 'matchlist',
      })
    end
  end

  -- return lines_with_matches
  local pattern = M.vim.fn.getreg('/')
  if pattern == '' or M.vim.v.hlsearch == 0 then
    return {}
  end

  if M.vim.o.ignorecase and not M.vim.o.ignorecase then
    pattern = '\\C' .. pattern
  end

  local lines_with_matches = {}

  local lines = M.vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

  for lnum, line in pairs(lines) do
    -- Convert to string to handle special buffers (e.g., ex history) that may return Blob objects
    local line_str = tostring(line)
    if M.vim.fn.match(line_str, pattern) ~= -1 then
      table.insert(lines_with_matches, {
        lnum = lnum,
        text = "/ ",
        texthl = "Comment",
        priority = 10,
      })
    end
  end

  return lines_with_matches
end


function M.enable(settings, winid)
end


function M.disable(settings, winid)
end

return M
