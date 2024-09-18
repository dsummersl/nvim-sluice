test:
	nvim --headless -c "PlenaryBustedDirectory tests/plenary/"

lint:
	luacheck lua/*

.PHONY: test lint
