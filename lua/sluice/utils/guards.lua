local M = {}

function M.win_exists(winid)
  return vim.tbl_contains(vim.api.nvim_list_wins(), winid)
end

return M
