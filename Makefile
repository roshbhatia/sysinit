# Color definitions
BLUE := \033[1;34m
GREEN := \033[1;32m
RED := \033[1;31m
YELLOW := \033[1;33m
NC := \033[0m # No Color
INFO := @printf "$(BLUE)%s$(NC)\n"
SUCCESS := @printf "$(GREEN)%s$(NC)\n"
WARN := @printf "$(YELLOW)%s$(NC)\n"
ERROR := @printf "$(RED)%s$(NC)\n"

.PHONY: refresh build update-flake clean test refresh-work help

# System configuration targets
refresh:
	$(INFO) "🔄 Applying system configuration..."
	@darwin-rebuild switch --flake . --show-trace && \
	$(SUCCESS) "✅ System configuration applied successfully"

build:
	$(INFO) "🏗️  Building system configuration..."
	@darwin-rebuild build --flake . && \
	$(SUCCESS) "✅ Build completed successfully"

update-flake:
	$(INFO) "📦 Updating flake inputs..."
	@nix flake update && \
	$(SUCCESS) "✅ Flake inputs updated successfully"

# Maintenance targets
clean:
	$(INFO) "🧹 Running garbage collection..."
	@sudo nix-collect-garbage -d && \
	$(SUCCESS) "✅ Garbage collection completed"

test:
	$(INFO) "🧪 Running test suite..."
	@./tests/smart-resize-test.sh && \
	$(SUCCESS) "✅ Tests completed successfully"

# Work configuration targets
refresh-work:
	@WORK_SYSINIT=$$(find ~/github/work -maxdepth 2 -type d -name "sysinit" 2>/dev/null | head -n 1); \
	if [ -z "$$WORK_SYSINIT" ]; then \
		$(ERROR) "❌ Could not find work sysinit repository"; \
		exit 1; \
	fi; \
	$(INFO) "🔄 Refreshing work sysinit at $$WORK_SYSINIT"; \
	cd "$$WORK_SYSINIT" && \
	if ! nix flake update; then \
		$(ERROR) "❌ Failed to update flake"; \
		exit 1; \
	fi && \
	if ! nix build; then \
		$(ERROR) "❌ Failed to build configuration"; \
		exit 1; \
	fi && \
	if ! ./result/sw/bin/darwin-rebuild switch --flake .#default; then \
		$(ERROR) "❌ Failed to apply configuration"; \
		exit 1; \
	fi && \
	$(SUCCESS) "✅ Work configuration refreshed successfully"

# Help target
help:
	@echo "$(BLUE)SysInit Makefile Commands:$(NC)"
	@echo ""
	@echo "$(BLUE)System Configuration:$(NC)"
	@echo "  $(GREEN)make refresh$(NC)      - Apply the system configuration"
	@echo "  $(GREEN)make build$(NC)        - Build the configuration without applying"
	@echo "  $(GREEN)make update-flake$(NC) - Update flake inputs"
	@echo ""
	@echo "$(BLUE)Maintenance:$(NC)"
	@echo "  $(GREEN)make clean$(NC)        - Run garbage collection"
	@echo "  $(GREEN)make test$(NC)         - Run test suite"
	@echo ""
	@echo "$(BLUE)Work Configuration:$(NC)"
	@echo "  $(GREEN)make refresh-work$(NC) - Update and rebuild work sysinit configuration"