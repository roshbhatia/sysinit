{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.sysinit.traces;

  declared = lib.filterAttrs (_harness: sources: sources != null) cfg.providers;

  file = ".config/sysinit/traces.json";
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

  # traces reads the file at runtime rather than an environment variable, so a
  # new declaration reaches a shell that was already open. A sessionVariable
  # needs a fresh login before the process sees it.
  config = lib.mkIf (declared != { }) {
    home.file.${file}.text = builtins.toJSON { providers = declared; };
  };
}
