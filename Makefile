SHELL := /bin/bash
# Color definitions
BLUE := $(shell printf '\033[1;34m')
GREEN := $(shell printf '\033[1;32m')
RED := $(shell printf '\033[1;31m')
YELLOW := $(shell printf '\033[1;33m')
NC := $(shell printf '\033[0m')
INFO := $(BLUE)%s$(NC)\n
SUCCESS := $(GREEN)%s$(NC)\n
WARN := $(YELLOW)%s$(NC)\n
ERROR := $(RED)%s$(NC)\n

.PHONY: refresh build update-flake clean test refresh-work test-neovim help

# System configuration targets
refresh:
	printf "$(INFO)" "🔄 Applying system configuration..."
	@darwin-rebuild switch --flake . --show-trace && \
	printf "$(SUCCESS)" "✅ System configuration applied successfully"

build:
	printf "$(INFO)" "🏗️  Building system configuration..."
	@darwin-rebuild build --flake . && \
	printf "$(SUCCESS)" "✅ Build completed successfully"

update-flake:
	printf "$(INFO)" "📦 Updating flake inputs..."
	@nix flake update && \
	printf "$(SUCCESS)" "✅ Flake inputs updated successfully"

# Maintenance targets
clean:
	printf "$(INFO)" "🧹 Running garbage collection..."
	@sudo nix-collect-garbage -d && \
	printf "$(SUCCESS)" "✅ Garbage collection completed"

test:
	printf "$(INFO)" "🧪 Running test suite..."
	@./tests/smart-resize-test.sh && \
	printf "$(SUCCESS)" "✅ Tests completed successfully"

# Work configuration targets
refresh-work:
	@WORK_SYSINIT=$$(find ~/github/work -maxdepth 2 -type d -name "sysinit" 2>/dev/null | head -n 1); \
	if [ -z "$$WORK_SYSINIT" ]; then \
		printf "$(ERROR)" "❌ Could not find work sysinit repository"; \
		exit 1; \
	fi; \
	printf "$(INFO)" "🔄 Refreshing work sysinit at $$WORK_SYSINIT"; \
	cd "$$WORK_SYSINIT" && \
	if ! nix flake update; then \
		printf "$(ERROR)" "❌ Failed to update flake"; \
		exit 1; \
	fi && \
	if ! nix build; then \
		printf "$(ERROR)" "❌ Failed to build configuration"; \
		exit 1; \
	fi && \
	if ! ./result/sw/bin/darwin-rebuild switch --flake .#default; then \
		printf "$(ERROR)" "❌ Failed to apply configuration"; \
		exit 1; \
	fi && \
	printf "$(SUCCESS)" "✅ Work configuration refreshed successfully"

# Neovim test target
test-neovim:
	@printf "$(INFO)" "🧪 Testing Neovim configuration..."
	@cd $(PWD)/modules/home/neovim && \
	NVIM_APPNAME=sysinit-nvim nvim -u init.lua && \
	printf "$(SUCCESS)" "✅ Neovim test completed"

# Help target
help:
	@printf "$(BLUE)%s$(NC)\n" "SysInit Makefile Commands:"
	@printf "\n"
	@printf "$(BLUE)%s$(NC)\n" "System Configuration:"
	@printf "  $(GREEN)%s$(NC)      - %s\n" "make refresh" "Apply the system configuration"
	@printf "  $(GREEN)%s$(NC)        - %s\n" "make build" "Build the configuration without applying"
	@printf "  $(GREEN)%s$(NC) - %s\n" "make update-flake" "Update flake inputs"
	@printf "\n"
	@printf "$(BLUE)%s$(NC)\n" "Maintenance:"
	@printf "  $(GREEN)%s$(NC)        - %s\n" "make clean" "Run garbage collection"
	@printf "  $(GREEN)%s$(NC)         - %s\n" "make test" "Run test suite"
	@printf "\n"
	@printf "$(BLUE)%s$(NC)\n" "Development:"
	@printf "  $(GREEN)%s$(NC)   - %s\n" "make test-neovim" "Test Neovim configuration in isolation"
	@printf "\n"
	@printf "$(BLUE)%s$(NC)\n" "Work Configuration:"
	@printf "  $(GREEN)%s$(NC) - %s\n" "make refresh-work" "Update and rebuild work sysinit configuration"