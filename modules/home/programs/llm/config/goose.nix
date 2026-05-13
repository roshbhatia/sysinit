{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  gooseConfig = builtins.toJSON {
    EDIT_MODE = "vi";
    GOOSE_CLI_MIN_PRIORITY = 0.2;
    GOOSE_CLI_THEME = "ansi";
    GOOSE_MODE = "smart_approve";
    GOOSE_TOOLSHIM = true;

    extensions = llmLib.mcp.formatForGoose kit.mcpServers.servers;
    # goose's existing shell allowlist is sourced from mcp.nix's categorized
    # permissions (git/github/docker/k8s/nix/utilities/crossplane). Migrating
    # to the canonical Tier A would change the semantic surface; deferred to
    # a future revisit. The kit migration above unifies imports only.
    shell = llmLib.mcp.formatPermissionsForGoose kit.mcpServers.allPermissions;
  };

  # Goose's runtime wants to mutate this file (e.g., when the user
  # answers the first-run telemetry prompt). xdg.configFile would symlink
  # it from the read-only nix store, and goose then fails with
  # "Too many symlink levels (or a cycle)" while trying to rewrite.
  # We materialize a writable copy via home.activation instead, mirroring
  # the updatePiSettings pattern from pi.nix.
  gooseConfigBase = pkgs.writeText "goose-config-base.json" gooseConfig;

  updateGooseConfig = pkgs.writeShellScript "update-goose-config" ''
    set -euo pipefail

    target="$HOME/.config/goose/config.yaml"
    target_dir="$(dirname "$target")"
    mkdir -p "$target_dir"

    # If the existing file is a symlink (left over from the old
    # xdg.configFile setup), replace it outright. Otherwise deep-merge
    # any keys goose has added at runtime (telemetry, etc.) with our
    # nix-managed base.
    if [ -L "$target" ]; then
      rm -f "$target"
    fi

    merged="$(mktemp "''${target}.tmp.XXXXXX")"
    trap 'rm -f "$merged"' EXIT

    if [ -f "$target" ]; then
      # yq (mikefarah/yq) handles both JSON and YAML input. eval-all reads
      # every doc and ireduce merges them; the later doc (our nix base)
      # wins on conflict for canonical fields, while goose's runtime
      # additions (e.g. telemetry consent) are preserved from the first.
      ${pkgs.yq-go}/bin/yq eval-all \
        '. as $item ireduce ({}; . * $item)' \
        "$target" ${gooseConfigBase} > "$merged"
    else
      cp ${gooseConfigBase} "$merged"
    fi

    mv "$merged" "$target"
    chmod u+w "$target"
  '';

  # Goose recipes shipped here mirror the four canonical openspec workflow
  # phases. Each recipe's `prompt` is sourced from the same Nix string the
  # corresponding Claude skill uses — single source of truth.
  recipes = {
    openspec-propose = {
      description = "Propose a new OpenSpec change with proposal, design, specs, and tasks artifacts.";
      body = import ../skills/openspec-propose.nix;
    };
    openspec-apply = {
      description = "Implement the tasks defined in an existing OpenSpec change.";
      body = import ../skills/openspec-apply.nix;
    };
    openspec-explore = {
      description = "Enter explore mode — a thinking-partner stance for clarifying requirements before committing to a change.";
      body = import ../skills/openspec-explore.nix;
    };
    openspec-archive = {
      description = "Archive a completed OpenSpec change and merge its delta specs into the project's authoritative specs.";
      body = import ../skills/openspec-archive.nix;
    };
  };

  mkRecipe =
    name: r:
    let
      title = "OpenSpec: " + lib.removePrefix "openspec-" name;
    in
    builtins.toJSON {
      version = "1.0.0";
      inherit title;
      inherit (r) description;
      prompt = r.body;
    };

  recipeFiles = builtins.mapAttrs (name: r: pkgs.writeText "${name}.yaml" (mkRecipe name r)) recipes;
in
{
  home.sessionVariables = {
    CONTEXT_FILE_NAMES = builtins.toJSON [
      "AGENTS.md"
      ".goosehints"
      ".cursorrules"
      "CLAUDE.md"
      "CONSTITUTION.md"
      "CONTRIBUTING.md"
      "COPILOT.md"
    ];
    GOOSE_RECIPE_PATH = "${config.home.homeDirectory}/.config/goose/recipes";
  };

  home.activation.gooseConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${updateGooseConfig}
  '';

  # Recipes are read-only, so symlinks from the nix store are fine.
  xdg.configFile = lib.mapAttrs' (
    name: file:
    lib.nameValuePair "goose/recipes/${name}.yaml" {
      source = file;
      force = true;
    }
  ) recipeFiles;

  home.packages = [ pkgs.goose-cli ];
}
