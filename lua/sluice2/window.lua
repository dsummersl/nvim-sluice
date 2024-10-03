local M = {}

function M.new(bufnr)
  local window = {
    bufnr = bufnr,
    ns_id = vim.api.nvim_create_namespace('sluice_window_' .. bufnr)
  }

  function window:update()
    local win_height = vim.api.nvim_win_get_height(0)
    local buf_lines = vim.api.nvim_buf_line_count(self.bufnr)
    local top_line = vim.fn.line('w0')
    local bottom_line = vim.fn.line('w$')

    -- Clear existing virtual text
    vim.api.nvim_buf_clear_namespace(self.bufnr, self.ns_id, 0, -1)

    -- Add virtual text to show buffer position
    local position = string.format("Lines %d-%d of %d", top_line, bottom_line, buf_lines)
    vim.api.nvim_buf_set_virtual_text(self.bufnr, self.ns_id, 0, {{position, "SluiceWindow"}}, {})
  end

  function window:clear()
    vim.api.nvim_buf_clear_namespace(self.bufnr, self.ns_id, 0, -1)
  end

  return window
end

return M
