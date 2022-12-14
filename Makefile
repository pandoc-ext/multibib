DIFF ?= diff
PANDOC ?= pandoc

# Use special expected output file if it exists.
expected_output = test/expected.$(PANDOC_VERSION).txt
ifeq ($(wildcard $(expected_output)),)
expected_output = test/expected.txt
endif

test: test/input.md multiple-bibliographies.lua
	@$(PANDOC) -d test/test.yaml \
	    | $(DIFF) $(expected_output) -

.PHONY: test
