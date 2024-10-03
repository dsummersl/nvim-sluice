local M = {}

function M.new(bufnr)
  local gutter = {
    bufnr = bufnr,
    ns_id = vim.api.nvim_create_namespace('sluice_gutter_' .. bufnr),
    visible = false,
    width = 1,
    layout = 'right'
  }

  function gutter:show()
    if not self.visible then
      self.visible = true
      vim.api.nvim_buf_set_option(self.bufnr, 'signcolumn', 'yes:' .. self.width)
      self:update()
    end
  end

  function gutter:hide()
    if self.visible then
      self.visible = false
      vim.api.nvim_buf_set_option(self.bufnr, 'signcolumn', 'no')
      vim.api.nvim_buf_clear_namespace(self.bufnr, self.ns_id, 0, -1)
    end
  end

  function gutter:update()
    if self.visible then
      vim.api.nvim_buf_clear_namespace(self.bufnr, self.ns_id, 0, -1)
      -- This is where we'll add the logic to update the gutter content
      -- For now, let's just add a placeholder sign
      vim.fn.sign_define('SluicePlaceholder', { text = '▌', texthl = 'SluiceGutter' })
      vim.fn.sign_place(0, self.ns_id, 'SluicePlaceholder', self.bufnr, { lnum = 1, priority = 10 })
    end
  end

  return gutter
end

return M
