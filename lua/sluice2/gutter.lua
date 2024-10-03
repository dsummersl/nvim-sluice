local M = {}

function M.new(bufnr)
  local gutter = {
    bufnr = bufnr,
    ns_id = vim.api.nvim_create_namespace('sluice_gutter_' .. bufnr),
    visible = false
  }

  function gutter:show()
    self.visible = true
    -- Implement gutter showing logic here
  end

  function gutter:hide()
    self.visible = false
    -- Implement gutter hiding logic here
  end

  function gutter:update()
    if self.visible then
      -- Implement gutter update logic here
    end
  end

  return gutter
end

return M
