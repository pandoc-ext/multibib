DIFF ?= diff
PANDOC ?= pandoc

test: test/input.md multiple-bibliographies.lua
	@$(PANDOC) -d test/test.yaml \
	    | $(DIFF) - test/expected.txt

.PHONY: test
