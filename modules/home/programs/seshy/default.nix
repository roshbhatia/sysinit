{
  config,
  lib,
  pkgs,
  ...
}:
let
  syFishCompletion = pkgs.runCommand "sy-fish-completion" { } ''
    export HOME="$TMPDIR"
    export XDG_CONFIG_HOME="$TMPDIR/config"
    ${lib.getExe pkgs.seshy} completion fish > "$out"
  '';

  settings = {
    branchFormat = "dev/{{.User}}/{{.Session}}/{{.Repo}}";
    sessionsDir = config.sysinit.paths.resolved.seshySessions;
    hooks = {
      postCreate = config.sysinit.seshy.postCreateHooks;
      preDelete = [ ];
    };
  };
in
{
  options.sysinit.seshy = {
    postCreateHooks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Explicit commands to run after session creation.";
    };
  };
  config.xdg.configFile = {
    "seshy/config.yaml".source = (pkgs.formats.yaml { }).generate "seshy-config.yaml" settings;
    "fish/completions/sy.fish".source = syFishCompletion;
  };
}
