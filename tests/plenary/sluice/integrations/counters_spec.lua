local counters = require('sluice.integrations.counters')

describe('count()', function()
  it('returns an empty string for <= 0', function()
    for _, values in pairs(counters.methods) do
      assert.are.equal(' ', counters.count(0, values))
      assert.are.equal(' ', counters.count(-1, values))
    end
  end)

  it('returns a value for 1', function ()
    for _, values in pairs(counters.methods) do
      assert.are.equal(values[1], counters.count(1, values))
    end
  end)

  it('returns a max value for big numbers', function ()
    for _, values in pairs(counters.methods) do
      assert.are.equal(values[#values], counters.count(100, values))
    end
  end)
end)
