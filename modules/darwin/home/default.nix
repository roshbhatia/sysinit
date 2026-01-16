# Darwin home-manager configuration
{
  imports = [
    ./desktop.nix
    ./configurations/firefox # Keep firefox separate - it's large
  ];
}
