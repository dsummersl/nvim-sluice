local xxhash32 = require('sluice.luaxxhash')

local function memoize(func)
  local cache = {}
  local call_count = 0

  -- The memoized function object (a table)
  local memoized_func = {}

  -- The actual function that does the memoization
  local function memoized_call(self, ...)
    call_count = call_count + 1
    -- Create a unique key based on the function's arguments
    local key = {}
    local n = select('#', ...)
    for i = 1, n do
      local arg = select(i, ...)
      table.insert(key, tostring(arg))
    end
    local key_str = table.concat(key, ":")

    -- Check if the result is already cached
    if cache[key_str] then
      return cache[key_str]
    else
      local result = func(...)
      cache[key_str] = result
      return result
    end
  end

  -- Set the __call metamethod to make the table callable
  setmetatable(memoized_func, {
    __call = memoized_call
  })

  -- Method to clear the memoized data
  function memoized_func.clear_cache()
    cache = {}
  end

  -- Method to report statistics about the memoized function
  function memoized_func.stats()
    local cache_size = 0
    local total_size = 0
    for k, v in pairs(cache) do
      cache_size = cache_size + 1
      -- Estimate memory usage of keys and values
      total_size = total_size + #k + (type(v) == "string" and #v or 0)
    end
    return {
      cache_size = cache_size,
      cache_memory = total_size,
      total_calls = call_count
    }
  end

  return memoized_func
end

return memoize
