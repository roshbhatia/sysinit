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
  providerNames = builtins.attrNames pkgs.traces-providers.providers;

  declared = lib.filterAttrs (_harness: sources: sources != null) cfg.providers;
  defaultSources = {
    claude-code = [ "claude" ];
    codex = [ "codex" ];
    codex_cli_rs = [ "codex" ];
    opencode = [ "opencode" ];
  };
  sources = defaultSources // declared;
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
      (lib.lowPrio pkgs.traces-providers)
    ];

    # Traces reads the file at runtime, so provider changes reach a shell that
    # was already open. Private providers remain ordinary commands on PATH.
    xdg.configFile =
      builtins.listToAttrs (
        map (name: {
          name = "traces/providers/${name}/provider.yaml";
          value.source = "${pkgs.traces-providers}/share/traces/providers/${name}/provider.yaml";
        }) providerNames
      )
      // {
        "traces/config.yaml".source = yamlFormat.generate "traces-config.yaml" {
          color = "auto";
          diff.provider = "git";
          clipboard.provider = "desktop";
          editor.provider = "desktop";
          providers.directory = "${config.xdg.configHome}/traces/providers";
          inherit sources;
        };
      };
  };
}
