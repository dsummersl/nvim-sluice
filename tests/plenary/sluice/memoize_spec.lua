local memoize = require('sluice.memoize')

describe('memoize', function()
  it('should return a function', function()
    local memoized = memoize(function() end)
    assert.is_table(memoized)
  end)

  it('should memoize function results', function()
    local call_count = 0
    local function expensive_function(x)
      call_count = call_count + 1
      return x * 2
    end

    local memoized = memoize(expensive_function)

    -- First call should execute the function
    assert.equal(4, memoized(2))
    assert.equal(1, call_count)

    -- Second call with same argument should return memoized result
    assert.equal(4, memoized(2))
    assert.equal(1, call_count)

    -- Call with different argument should execute the function again
    assert.equal(6, memoized(3))
    assert.equal(2, call_count)
  end)

  it('should handle multiple arguments', function()
    local memoized = memoize(function(a, b) return a + b end)

    assert.equal(5, memoized(2, 3))
    assert.equal(5, memoized(2, 3))
    assert.equal(7, memoized(3, 4))
  end)

  it('should clear cache', function()
    local call_count = 0
    local memoized = memoize(function(x)
      call_count = call_count + 1
      return x * 2
    end)

    memoized(2)
    memoized(2)
    assert.equal(1, call_count)

    memoized.clear_cache()
    memoized(2)
    assert.equal(2, call_count)
  end)

  it('should report cache size', function()
    local memoized = memoize(function(x) return x * 2 end)

    assert.equal(0, memoized.cache_size())
    memoized(2)
    assert.equal(1, memoized.cache_size())
    memoized(3)
    assert.equal(2, memoized.cache_size())
    memoized(2)
    assert.equal(2, memoized.cache_size())
  end)

  it('should estimate cache memory', function()
    local memoized = memoize(function(x) return string.rep('a', x) end)

    assert.equal(0, memoized.cache_memory())
    memoized(5)
    assert.is_true(memoized.cache_memory() > 0)
    local mem_after_first = memoized.cache_memory()
    memoized(10)
    assert.is_true(memoized.cache_memory() > mem_after_first)
  end)
end)
local memoize = require('sluice.memoize')

describe("memoize", function()
  it("should correctly cache table parameters", function()
    local function expensive_function(t)
      -- Simulate an expensive operation
      vim.loop.sleep(100)
      return t.a + t.b
    end

    local memoized_func = memoize(expensive_function)

    -- First call with a table
    local start_time = vim.loop.hrtime()
    local result1 = memoized_func({a = 5, b = 3})
    local end_time = vim.loop.hrtime()
    local first_duration = (end_time - start_time) / 1e6  -- Convert to milliseconds

    assert.are.equal(8, result1)
    assert.is_true(first_duration >= 100)  -- Should take at least 100ms

    -- Second call with the same table (should be faster due to caching)
    start_time = vim.loop.hrtime()
    local result2 = memoized_func({a = 5, b = 3})
    end_time = vim.loop.hrtime()
    local second_duration = (end_time - start_time) / 1e6  -- Convert to milliseconds

    assert.are.equal(8, result2)
    assert.is_true(second_duration < 10)  -- Should be much faster, let's say less than 10ms

    -- Call with a different table (should take longer again)
    start_time = vim.loop.hrtime()
    local result3 = memoized_func({a = 10, b = 7})
    end_time = vim.loop.hrtime()
    local third_duration = (end_time - start_time) / 1e6  -- Convert to milliseconds

    assert.are.equal(17, result3)
    assert.is_true(third_duration >= 100)  -- Should take at least 100ms again
  end)

  it("should handle nested tables correctly", function()
    local function nested_sum(t)
      vim.loop.sleep(100)
      return t.x.y + t.x.z
    end

    local memoized_nested = memoize(nested_sum)

    -- First call with a nested table
    local result1 = memoized_nested({x = {y = 5, z = 3}})
    assert.are.equal(8, result1)

    -- Second call with the same nested structure (should be cached)
    local start_time = vim.loop.hrtime()
    local result2 = memoized_nested({x = {y = 5, z = 3}})
    local end_time = vim.loop.hrtime()
    local duration = (end_time - start_time) / 1e6  -- Convert to milliseconds

    assert.are.equal(8, result2)
    assert.is_true(duration < 10)  -- Should be much faster, let's say less than 10ms
  end)
end)
