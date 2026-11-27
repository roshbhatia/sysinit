{ pkgs }:
let
  inherit (pkgs) lib;

  probeInputs = lib.fileset.toSource {
    root = ../../.;
    fileset = lib.fileset.unions [
      ../../modules/home/programs/utils/dev/connect.nu
      ../../modules/home/programs/utils/dev/fzf-preview.nu
      ../../modules/home/programs/utils/network/dns-flush.nu
      ../../modules/home/programs/utils/system/set-background.nu
      ../../features/shell/zsh/integrations/ask.zsh
      ../../features/shell/zsh/integrations/seshy-wezterm.zsh
      ../../modules/darwin/home/sketchybar/lua/sysinit/pkg/core/display.lua
      ../../modules/darwin/home/hammerspoon/lua/sysinit/pkg/utils/json_loader.lua
      ../../modules/darwin/sketchybar-health.nu
      ../desktop/sketchybar-health.nu
      ../fixtures/sketchybar-command.nu
    ];
  };
in
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
      "${probeInputs}"
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
      "${probeInputs}"
    ]
    [
      "nu"
      "--no-config-file"
      "${(import ../lib/probe-source.nix { inherit lib; }) ../host/log-retention.nu [
        ../lib/process.nu
      ]}"
    ]
    [
      "nu"
      "--no-config-file"
      "${probeInputs}/checks/desktop/sketchybar-health.nu"
    ]
  ];
}
