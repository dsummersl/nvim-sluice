test:
	nvim --headless -c "PlenaryBustedDirectory tests/plenary/ {minimal_init = 'tests/minimal_init.vim'}"

lint:
	luacheck lua/*

.PHONY: test lint
