# Bashing — developer entry points.
#
# Every target delegates to a script in scripts/ so that CI, editors and humans
# run byte-identical commands. Add logic to the scripts, not here.

SHELL := bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

.PHONY: help
help: ## Show this help
	@echo "Bashing — available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "} {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

.PHONY: check
check: lint fmt-check test ## Run everything CI runs

.PHONY: lint
lint: ## Syntax-check and shellcheck all shell files
	@scripts/lint.sh

.PHONY: fmt
fmt: ## Reformat all shell files in place
	@scripts/fmt.sh

.PHONY: fmt-check
fmt-check: ## Fail if any shell file is misformatted
	@scripts/fmt.sh --check

.PHONY: test
test: ## Run the test suite
	@scripts/test.sh

.PHONY: install
install: ## Symlink bin/bashing into PREFIX/bin (default /usr/local/bin)
	@mkdir -p "$(DESTDIR)$(BINDIR)"
	@ln -sf "$(CURDIR)/bin/bashing" "$(DESTDIR)$(BINDIR)/bashing"
	@echo "installed $(DESTDIR)$(BINDIR)/bashing -> $(CURDIR)/bin/bashing"

.PHONY: uninstall
uninstall: ## Remove the symlink created by make install
	@rm -f "$(DESTDIR)$(BINDIR)/bashing"
	@echo "removed $(DESTDIR)$(BINDIR)/bashing"
