{
  description = "Development project with Lima VM";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    sysinit.url = "github:roshbhatia/sysinit";
  };

  outputs =
    {
      nixpkgs,
    }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = import ./shell.nix { inherit pkgs; };
    };
}
