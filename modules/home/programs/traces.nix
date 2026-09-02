{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.sysinit.traces;
  yamlFormat = pkgs.formats.yaml { };

  declared = lib.filterAttrs (_harness: sources: sources != null) cfg.providers;
  defaultSources = {
    claude-code = [ "claude" ];
    codex = [ "codex" ];
    codex_cli_rs = [ "codex" ];
    opencode = [ "opencode" ];
  };
  sources = defaultSources // declared;
  providerNames = lib.unique (lib.concatLists (lib.attrValues sources));
  publicProviders = {
    claude = {
      command = [ (lib.getExe pkgs.traces-provider-claude) ];
      description = "Read Claude Code transcript activity";
    };
    codex = {
      command = [ (lib.getExe pkgs.traces-provider-codex) ];
      description = "Read Codex rollout activity";
    };
    opencode = {
      command = [ (lib.getExe pkgs.traces-provider-opencode) ];
      description = "Read OpenCode session activity";
    };
  };
  providerFor =
    name:
    (publicProviders.${name} or {
      command = [ "traces-${name}" ];
      description = "Read ${name} activity";
    }
    )
    // {
      capabilities = [ "activity" ];
    };
in
{
  options.sysinit.traces.providers = mkOption {
    type = types.attrsOf (types.listOf types.str);
    default = { };
    example = {
      claude-code = [
        "observe"
        "claude"
      ];
    };
    description = ''
      Which sources traces reads for each harness, keyed by the harness's own
      `service.name`. A harness named here replaces its built-in default rather
      than adding to it, and an empty list takes its source away.

      A source is either a name traces implements itself (`claude`, `codex`,
      `opencode`) or a name it resolves to `traces-<name>` on PATH, which is how
      a downstream flake adds one without changing traces.

      Leave this empty on a machine where every harness exports to the local
      collector. The defaults already read each harness that keeps its own
      activity on disk, so this is for the harness that needs a source beyond
      that: one whose export an organization redirects somewhere else.
    '';
  };

  config = {
    home.packages = [
      pkgs.traces-provider-claude
      pkgs.traces-provider-codex
      pkgs.traces-provider-opencode
    ];

    # Traces reads the file at runtime, so provider changes reach a shell that
    # was already open. Private providers remain ordinary commands on PATH.
    xdg.configFile."traces/config.yaml".source = yamlFormat.generate "traces-config.yaml" {
      color = "auto";
      diff.command = [
        (lib.getExe pkgs.changes)
        "difftool"
        "$LOCAL"
        "$REMOTE"
        "$MERGED"
      ];
      providers = lib.genAttrs providerNames providerFor;
      inherit sources;
    };
  };
}
