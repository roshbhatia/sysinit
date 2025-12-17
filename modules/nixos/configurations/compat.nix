{
  pkgs,
  ...
}:
{
  # FHS environment for running non-NixOS packages
  # Create a full FHS environment by command `fhs`
  environment.systemPackages = [
    (
      let
        base = pkgs.appimageTools.defaultFhsEnvArgs;
      in
      pkgs.buildFHSEnv (
        base
        // {
          name = "fhs";
          targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [ pkgs.pkg-config ];
          profile = "export FHS=1";
          runScript = "bash";
          extraOutputsToInstall = [ "dev" ];
        }
      )
    )
  ];

  # nix-ld: Run non-NixOS binaries on NixOS
  # https://github.com/Mic92/nix-ld
  #
  # nix-ld installs itself at `/lib64/ld-linux-x86-64.so.2` to act as a middleware between
  # the actual linker and non-NixOS binaries. It reads:
  #   - NIX_LD: points to the actual linker
  #   - NIX_LD_LIBRARY_PATH: sets LD_LIBRARY_PATH for the linker
  #
  # Default values are set automatically for basic compatibility.
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/programs/nix-ld.nix#L37-L40
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
    ];
  };
}
