test:
	busted tests

lint:
	luacheck lua/*

.PHONY: test lint
