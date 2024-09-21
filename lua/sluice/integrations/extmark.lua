local config = require('sluice.config')

local M = {
  vim = vim
}

function M.add_hl_groups(result, bufnr, settings, hl_group_type)
  -- lookup hl_groups or sign_hl_groups:
  local plugin_config = (settings.extmark and settings.extmark)
  if not plugin_config then
    return {}
  end
  local hl_groups = plugin_config[hl_group_type .. "s"]
  local text = plugin_config['text'] or ' '

  local extmarks = M.vim.api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, {details = true})

  for _, mark in ipairs(extmarks) do
    local row = mark[2]
    local details = mark[4]
    if details[hl_group_type] ~= nil and config.str_table_fn(hl_groups, details[hl_group_type]) then
      local row_text = details['sign_text'] or text
      local use_linehl = row_text == ' '
      table.insert(result, {
        lnum = row + 1,
        text = row_text,
        texthl = details[hl_group_type],
        linehl = (use_linehl and details[hl_group_type]) or nil,
        priority = details["priority"],
        plugin = 'extmark',
      })
    end
  end

  return result
end

--- Returns all 'signs' in the extmark buffer
function M.update(settings, bufnr)
  local results = {}
  M.add_hl_groups(results, bufnr, settings, 'sign_hl_group')
  M.add_hl_groups(results, bufnr, settings, 'hl_group')
  return results
end

function M.enable(_settings, _bufnr)
  -- TODO setup the listeners for this.
  -- Specific events to update on - DiagnosticChanged would be one
end

function M.disable(settings, _bufnr)
end

return M
