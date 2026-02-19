{
  config,
  pkgs,
  ...
}:

let
  cfg = config.sysinit.git;
  personalGithubUser = if cfg.personalUsername != null then cfg.personalUsername else cfg.username;
  workGithubUser = if cfg.workUsername != null then cfg.workUsername else cfg.username;

  # Wrapper for gh that auto-switches accounts based on directory
  gh-wrapped = pkgs.callPackage ../../pkgs/gh-wrapper.nix {
    inherit personalGithubUser workGithubUser;
  };
in
{
  programs.gh = {
    enable = true;
    package = gh-wrapped;

    gitCredentialHelper.enable = false;

    settings = {
      git_protocol = "https";
      prompt = "enabled";

      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };
}
