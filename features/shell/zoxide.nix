{ config, lib, ... }:
{
  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
  };
  home.sessionVariables._ZO_FZF_OPTS = lib.concatStringsSep " " (
    config.programs.fzf.defaultOptions
    ++ lib.mapAttrsToList (name: value: "--color=${name}:${value}") config.programs.fzf.colors
    ++ [
      "--no-multi"
      "--scheme=history"
      "--bind=ctrl-f:jump,jump:accept"
    ]
  );
}
