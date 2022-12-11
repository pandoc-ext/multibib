DIFF ?= diff --strip-trailing-cr -u
PANDOC ?= pandoc

test: test/input.md multiple-bibliographies.lua
	@$(PANDOC) -d test/test.yaml \
	    | $(DIFF) - test/expected.txt

.PHONY: test
