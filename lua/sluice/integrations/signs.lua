local M = {
  vim = vim
}

--- Get a table with keys set to the `name` of each sign that is defined.
local function sign_getdefined()
  local get_defined = M.vim.fn.sign_getdefined()
  local signs_defined = {}
  for _, v in ipairs(get_defined) do
    signs_defined[v["name"]] = v
  end

  return signs_defined
end

--- Returns a table of signs, and whether they have changed since the last call to this method.
function M.update(settings, bufnr)
  local get_defined = sign_getdefined()
  -- TODO this should be settings.signs.group - but only if settings.signs exists!
  local group = settings.group or '*'
  local get_placed = M.vim.fn.sign_getplaced(bufnr, { group = group })

  -- local new_hash = xxh32(M.vim.inspect(get_placed))
  -- local _, old_hash = pcall(M.vim.api.nvim_buf_get_var, bufnr, 'sluice_last_defined')
  --
  -- if new_hash == old_hash then
  --   return get_defined
  -- end
  -- M.vim.api.nvim_buf_set_var(bufnr, 'sluice_last_defined', new_hash)

  local result = {}

  for _, v in ipairs(get_placed[1]["signs"]) do
    if v["name"] ~= "" then
      local line = M.vim.tbl_extend('force', get_defined[v["name"]], v)
      line.plugin = 'signs'
      table.insert(result, line)
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
