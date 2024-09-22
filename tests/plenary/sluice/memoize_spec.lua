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
