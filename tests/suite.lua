lu = require('luaunit')

require('tests/test_sluice')

runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
