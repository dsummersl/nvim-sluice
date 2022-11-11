local xxh32 = require("sluice.luaxxhash")

local M = {
  vim = vim
}

--- Returns a table of signs, and whether they have changed since the last call to this method.
function M.signs_changed(bufnr)
  local get_defined = M.vim.fn.sign_getdefined()
  local new_hash = xxh32(M.vim.inspect(get_defined))

  local _, old_hash = pcall(M.vim.api.nvim_buf_get_var, bufnr, 'sluice_last_defined')

  if new_hash == old_hash then
    return get_defined
  end

  M.vim.api.nvim_buf_set_var(bufnr, 'sluice_last_defined', new_hash)

  return get_defined
end

function M.enable(bufnr, ns, update_fn)
  -- TODO for now we just call it directly, but eventually we'd do this when we know of some events?
  update_fn(bufnr, ns, M.signs_changed(bufnr))
end

function M.disable(bufnr)
  local lines = M.signs_changed(bufnr)
  -- TODO this cleanup should happen elsewhere.
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
