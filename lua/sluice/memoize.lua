local xxhash32 = require('sluice.luaxxhash')

local function memoize(func)
  local cache = {}

  -- The memoized function object (a table)
  local memoized_func = {}

  -- The actual function that does the memoization
  local function memoized_call(self, ...)
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

  -- Method to report the size of the memoized data
  function memoized_func.cache_size()
    local count = 0
    for _ in pairs(cache) do
      count = count + 1
    end
    return count
  end

  -- Method to estimate memory usage of the memoized data
  function memoized_func.cache_memory()
    local total_size = 0
    for k, v in pairs(cache) do
      -- Estimate memory usage of keys and values
      total_size = total_size + #k + (type(v) == "string" and #v or 0)
    end
    return total_size
  end

  return memoized_func
end

return memoize
