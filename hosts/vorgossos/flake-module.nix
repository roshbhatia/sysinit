{ inputs, ... }:
let
  inherit (inputs.nixpkgs.lib) nixosSystem;
  personal = import ../personal.nix;
in
{
  flake.nixosConfigurations.vorgossos = nixosSystem {
    specialArgs = {
      inherit inputs;
      inherit (inputs) k0s-nix;
      inherit (personal) authorizedKeys;
      base16 = inputs.stylix.inputs.base16.lib;
      themeSchemes = inputs.theme-schemes;
      wezterm = inputs.wezterm-fork.packages.x86_64-linux.default;
    };
    modules = [ ./. ];
  };
}
