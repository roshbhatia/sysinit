{
  inputs,
  username,
  homeDirectory,
  userConfig,
  ...
}:
{
  imports = [
    ./configurations
    ./packages
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];
}
