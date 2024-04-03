local function debounce(func, delay)
  local timer_id = nil
  return function(...)
    local args = { ... }
    if not timer_id then
      func(unpack(args))
    else
      vim.fn.timer_stop(timer_id)
      timer_id = vim.fn.timer_start(delay, function()
        func(unpack(args))
        timer_id = nil
      end)
    end
  end
end

return debounce
