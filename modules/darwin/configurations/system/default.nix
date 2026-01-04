{
  values,
  pkgs,
  ...
}:
{
  nix.enable = false;

  environment.shells = [
    pkgs.bashInteractive
    pkgs.nushell
    pkgs.zsh
  ];

  system = {
    defaults.LaunchServices.LSQuarantine = false;
    primaryUser = values.user.username;
    stateVersion = 4;
  };
}
