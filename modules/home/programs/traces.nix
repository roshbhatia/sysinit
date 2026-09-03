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
  changesProvider = yamlFormat.generate "traces-provider-changes.yaml" {
    version = "provider/v1";
    name = "changes";
    description = "Render repository diffs with Changes";
    command = [ (lib.getExe pkgs.changes) ];
    actions."diff.render" = {
      description = "Render a Git-compatible two-file diff";
      argv = [
        "difftool"
        "-color"
        "always"
        "-width"
        "{{ .Width }}"
        "{{ .Local }}"
        "{{ .Remote }}"
        "{{ .Merged }}"
      ];
    };
    requires.commands = [ "changes" ];
    defaults.timeout = "10s";
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

      Each source names a provider manifest. Public harness providers ship with
      Traces. A downstream flake can add another manifest and executable without
      changing Traces.

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
    xdg.configFile = {
      "traces/config.yaml".source = yamlFormat.generate "traces-config.yaml" {
        color = "auto";
        diff.provider = "changes";
        providers.directory = "${config.xdg.configHome}/traces/providers";
        inherit sources;
      };

      "traces/providers/changes/provider.yaml".source = changesProvider;
      "traces/providers/claude/provider.yaml".source =
        "${pkgs.traces-provider-claude}/share/traces/providers/claude/provider.yaml";
      "traces/providers/codex/provider.yaml".source =
        "${pkgs.traces-provider-codex}/share/traces/providers/codex/provider.yaml";
      "traces/providers/opencode/provider.yaml".source =
        "${pkgs.traces-provider-opencode}/share/traces/providers/opencode/provider.yaml";
    };
  };
}
