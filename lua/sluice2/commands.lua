local M = {}

function M.enable(buffer_data)
  if not buffer_data.enabled then
    buffer_data.enabled = true
    buffer_data.gutter:show()
    buffer_data.window:update()
  end
end

function M.disable(buffer_data)
  if buffer_data.enabled then
    buffer_data.enabled = false
    buffer_data.gutter:hide()
    buffer_data.window:clear()
  end
end

function M.toggle(buffer_data)
  if buffer_data.enabled then
    M.disable(buffer_data)
  else
    M.enable(buffer_data)
  end
end

return M
