test:
	# TODO move to busted: https://github.com/lunarmodules/busted
	nvim --headless -c "PlenaryBustedDirectory tests/plenary/"

lint:
	luacheck lua/*

.PHONY: test lint
