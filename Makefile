test:
	~/.luarocks/bin/busted -m 'lua/?.lua' tests

lint:
	~/.luarocks/bin/luacheck lua/*

.PHONY: test lint
