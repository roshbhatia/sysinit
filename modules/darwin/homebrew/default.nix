{ pkgs, lib, config, ... }:

let
  # Get the value of the includePersonal option or default to true
  includePersonal = if builtins.hasAttr "includePersonal" config.sysinit then 
                     config.sysinit.includePersonal
                   else 
                     true;
in
{
  # Define a new option for the sysinit module
  options.sysinit.includePersonal = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to include personal applications";
  };

  # Import the base homebrew configuration
  imports = [
    ./global.nix
  ] ++ lib.optionals includePersonal [
    ./personal.nix
  ];

  # Basic homebrew configuration
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    taps = [
      "homebrew/cask"
      "homebrew/cask-fonts"
    ];
  };
}