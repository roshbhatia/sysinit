.PHONY: switch build update-flake clean test

switch:
	darwin-rebuild switch --flake . --show-trace

build:
	darwin-rebuild build --flake .

update-flake:
	nix flake update

clean:
	sudo nix-collect-garbage -d

test:
	@echo "🧪 Running tests..."
	@./tests/smart-resize-test.sh

help:
	@echo "SysInit Makefile Commands:"
	@echo "  make switch       - Apply the configuration"
	@echo "  make build        - Build the configuration without applying"
	@echo "  make update-flake - Update flake inputs"
	@echo "  make clean        - Run garbage collection"
	@echo "  make test         - Run test suite"