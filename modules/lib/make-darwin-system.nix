{ inputs, configValidator, fileInstaller }:
{ configPath ? ../config.nix }:
let
  config = configValidator configPath;
  username = config.user.username;
  hostname = config.user.hostname;
  homeDirectory = "/Users/${username}";
  system = "aarch64-darwin";
in
inputs.darwin.lib.darwinSystem {
  inherit system;
  specialArgs = { 
    inherit inputs username homeDirectory;
    userConfig = config;
    enableHomebrew = true;
  };
  modules = [
    ../modules/darwin/default.nix
    { networking.hostName = hostname; }
    (fileInstaller { inherit (inputs) nixpkgs; inherit config; })
  ];
}
