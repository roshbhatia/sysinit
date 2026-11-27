{
  flake.modules.homeManager.wezterm = ./home.nix;
  perSystem = { pkgs, ... }: {
    packages.ty = pkgs.sysinit-ty;
  };
}
