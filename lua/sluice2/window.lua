local M = {}

function M.new(bufnr)
  local window = {
    bufnr = bufnr
  }

  function window:update()
    -- Implement window update logic here
  end

  function window:clear()
    -- Implement window clearing logic here
  end

  return window
end

return M
