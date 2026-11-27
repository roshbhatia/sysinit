{ pkgs }:
let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv.hostPlatform) system;
  harnesses = import ../modules/home/programs/llm/harnesses/registry.nix;
  onDemand = lib.unique (
    lib.filter (name: name != null) (lib.mapAttrsToList (_: h: h.package) harnesses)
    ++ [
      "agents"
      "conductor-cli"
      "goose-desktop"
      "hunk"
      "task-board"
      "task-queue"
      "tq"
      "tq-terminal-wezterm"
    ]
  );
  candidates = pkgs // {
    agents = import ../modules/home/programs/llm/runtime/agents { inherit pkgs; };
  };
in
{
  cacheBundle = import ./cache.nix { inherit pkgs; };

  cloudTools = pkgs.symlinkJoin {
    name = "sysinit-cloud-tools-${system}";
    paths = map (name: pkgs.${name}) [
      "ask"
      "gate-cli"
      "gate-providers"
      "changes"
      "changes-providers"
      "traces"
      "traces-providers"
      "seshy"
      "calldiff"
      "sysinit-utils"
    ];
  };

  cloud-files =
    (import ./cloud-files.nix {
      inherit pkgs;
      inherit (pkgs) lib;
    }).all;
}
// lib.genAttrs (lib.filter (
  name: lib.meta.availableOn pkgs.stdenv.hostPlatform candidates.${name}
) onDemand) (name: candidates.${name})
