{
  lib,
  nixpkgs,
  inputs,
}:

{
  mkPkgs =
    {
      system,
      overlays ? [ ],
    }:
    import nixpkgs {
      inherit system overlays;
      config = {
        allowUnsupportedSystem = true;
        allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "1password"
            "1password-cli"
            "_1password-gui"
            "amp-cli"
            "antigravity-cli"
            "apple_cursor"
            "copilot-language-server"
            "cuda_cccl"
            "cuda_cudart"
            "cuda_nvcc"
            "cursor-cli"
            "devin-cli"
            "github-copilot-cli"
            "meat"
            "nvidia-kernel-modules"
            "nvidia-settings"
            "nvidia-x11"
            "obsidian"
            "steam"
            "steam-unwrapped"
            "upbound"
          ];
        allowInsecurePredicate = pkg: lib.hasPrefix "electron" (lib.getName pkg);
      };
    };

  mkOverlays = import ../../overlays/default.nix { inherit inputs; };
}
