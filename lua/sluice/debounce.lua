local function debounce(func, delay)
  local timer_id = nil
  return function(...)
    local args = { ... }
    if timer_id then
      vim.fn.timer_stop(timer_id)
    end
    timer_id = vim.fn.timer_start(delay, function()
      func(unpack(args))
    end)
  end
end

return debounce
