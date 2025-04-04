.PHONY: switch build update-flake clean

switch:
	darwin-rebuild switch --flake . --show-trace

build:
	darwin-rebuild build --flake .

update-flake:
	nix flake update

clean:
	sudo nix-collect-garbage -d

help:
	@echo "SysInit Makefile Commands:"
	@echo "  make switch       - Apply the configuration"
	@echo "  make build        - Build the configuration without applying"
	@echo "  make update-flake - Update flake inputs"
	@echo "  make clean        - Run garbage collection"