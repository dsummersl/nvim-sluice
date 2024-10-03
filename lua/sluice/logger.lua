local M = {
  vim = vim,
}

-- Path to the log file
local log_file_path = vim.fn.stdpath('data') .. '/sluice.log'

-- Function to log messages to the file
function M.log(context, message, level)
  level = level or "INFO"   -- Default level is INFO if not provided
  local log_message = string.format("[%s:%s] %s: %s\n", os.date("%Y-%m-%d %H:%M:%S"), context, level, message)

  -- Append the log message to the log file
  local file = io.open(log_file_path, "a")
  if file then
    file:write(log_message)
    file:close()
  else
    vim.api.nvim_err_writeln("Error: Could not open log file: " .. log_file_path)
  end
end

return M
