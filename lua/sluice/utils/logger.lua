local M = {
  level = "WARN",
}

-- Path to the log file
local log_file_path = vim.fn.stdpath('data') .. '/sluice.log'
local file = io.open(log_file_path, "a")

function M.set_level(level)
  M.level = level
end

local function level_enabled(level)
  if level == nil then
    return false
  end

  if level == "ERROR" then
    return true
  end

  if level == "WARN" and M.level ~= "ERROR" then
    return true
  end

  if level == "INFO" and M.level == "INFO" then
    return true
  end

  return false
end

-- Function to log messages to the file
-- @param context: string: The context in which the log message is being logged
-- @param message: string: The message to log
-- @param level: string | nil: The log level (INFO, WARN, ERROR, nil)
function M.log(context, message, level)
  if not level_enabled(level) then
    return
  end

  level = level or "INFO"   -- Default level is INFO if not provided
  local log_message = string.format("[%s:%s:%s] %s\n", os.date("%Y-%m-%d %H:%M:%S"), level, context, message)

  -- Append the log message to the log file
  -- TODO keep this open
  if file then
    file:write(log_message)
    file:flush()
  else
    vim.api.nvim_err_writeln("Error: Could not open log file: " .. log_file_path)
  end
end

function M.traceback(context)
  M.log(context, debug.traceback(), "ERROR")
end

return M
