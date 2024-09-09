local M = {
  vim = vim
}

--- Returns all 'signs' in the extmark buffer
function M.update(settings, bufnr)
  local hl_groups = settings.extmarks.hl_groups
  if not hl_groups then
    return {}
  end

  local extmarks = M.vim.api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, {details = true})

  local result = {}

  for _, mark in ipairs(extmarks) do
    local row = mark[2]
    local details = mark[4]
    if details['sign_hl_group'] ~= "" then
      table.insert(result, {
        lnum = row + 1,
        text = details["sign_text"],
        texthl = details["sign_hl_group"],
        -- linehl = details["hl_group"],
        priority = details["priority"],
        plugin = 'extmarks',
      })
    end
  end

  return result
end

function M.enable(_settings, _bufnr)
  -- TODO setup the listeners for this.
  -- Specific events to update on - DiagnosticChanged would be one
end

function M.disable(settings, bufnr)
  -- TODO this cleanup should happen elsewhere.
  local lines = M.update(settings, bufnr)
  if not lines then
    for _, v in ipairs(lines) do
      if v["texthl"] == "" then
        local line_text_hl = v["linehl"] .. v["texthl"]
        M.vim.api.nvim_exec("hi clear " .. line_text_hl, false)
      end
    end
  end
end

return M
