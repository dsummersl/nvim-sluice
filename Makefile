test:
	lua tests/suite.lua

lint:
	luacheck lua/*

.PHONY: test lint
