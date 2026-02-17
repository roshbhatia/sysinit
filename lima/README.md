# Lima NixOS VMs

Lima-based NixOS virtual machines for disposable development environments.

## Overview

This directory contains Lima templates for creating lightweight NixOS VMs that integrate with the sysinit configuration system. VMs use the profile system to compose functionality.

## Quick Start

Start a minimal NixOS VM:

```bash
limactl start --name=dev lima/templates/minimal.yaml
limactl shell dev
```

Stop and delete:

```bash
limactl stop dev
limactl delete dev
```

## Templates

### minimal.yaml

Basic NixOS VM with:
- 2 CPUs, 4GB RAM, 20GB disk
- Official NixOS cloud image
- SSH access with your public keys
- Mounts: ~/.ssh (ro), ~/projects (rw)
- Apple Virtualization (vz) for performance

## Configuration

VMs are configured via NixOS configurations in the flake:

- `lima-minimal`: Uses `dev-minimal` profile (basic neovim setup)
- `lima-dev`: Uses `dev-full` profile (complete dev environment)

## Profiles

Profiles are defined in `profiles/`:

- `dev-minimal`: Basic development (neovim, git, essential CLI tools)
- `dev-full`: Complete development environment (neovim, helix, LSPs, all tools)

## Architecture

- **Host**: macOS with Lima installed
- **VM**: NixOS with cloud-init, SSH, Nix daemon
- **Shared**: Projects directory mounted via virtiofs
- **Config**: Declarative via flake nixosConfigurations

## Validation

Validate configurations build:

```bash
task nix:build:lv426  # Or nix flake check
```

## Future Work

- Custom QCOW2 images (nixos-generators)
- Project-scoped VM templates
- Zellij integration
- Ghostty terminal integration
