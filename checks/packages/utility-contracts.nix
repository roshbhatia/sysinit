{ pkgs }:
import ../lib/native.nix { inherit pkgs; } {
  name = "utility-contracts";
  inputs = [
    pkgs.zsh
    pkgs.lua5_4
    pkgs.gnutar
    pkgs.gzip
    pkgs.bzip2
    pkgs._7zz
    pkgs.logrotate
  ];
  commands = [
    [
      "nu"
      "--no-config-file"
      ./utility-contracts.nu
      ../../.
      ../fixtures/utility-command.nu
    ]
    [
      "nu"
      "--no-config-file"
      ../agents/codex-plugin-hooks.nu
      ../../modules/home/programs/llm/harnesses/codex-plugin-hooks.nu
    ]
    [
      "lua"
      ../desktop/desktop-contracts.lua
      ../../.
    ]
    [
      "nu"
      "--no-config-file"
      "${(import ../lib/probe-source.nix { inherit (pkgs) lib; }) ../host/log-retention.nu [
        ../lib/process.nu
      ]}"
    ]
    [
      "nu"
      "--no-config-file"
      "${../../.}/checks/desktop/sketchybar-health.nu"
    ]
  ];
}
