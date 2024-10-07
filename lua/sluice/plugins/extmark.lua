local config = require('sluice.config')
local logger = require('sluice.logger')

local M = {
  vim = vim,
  auto_command_ids_by_bufnr = {}
}

local default_settings = {
  hl_group = nil,
  sign_hl_group = '.*',
  text = ' ',
  events = { 'DiagnosticChanged' },
  user_events = {},
}

function M.add_hl_groups(result, bufnr, settings, hl_group_type)
  -- lookup hl_groups or sign_hl_group:
  local update_settings = M.vim.tbl_deep_extend('keep', settings or {}, default_settings)

  local hl_groups = update_settings[hl_group_type]
  local text = update_settings['text']

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

function M.enable(settings, bufnr)
  local update_settings = M.vim.tbl_deep_extend('keep', settings or {}, default_settings)
  if #update_settings.events > 0 then
    local au_ids = config.trigger_update_on_event(update_settings.events, update_settings.user_events)
    table.insert(M.auto_command_ids_by_bufnr, bufnr, au_ids)
  end

  return update_settings
end

function M.disable(settings, bufnr)
  config.remove_autocmds(bufnr)
end

return M
