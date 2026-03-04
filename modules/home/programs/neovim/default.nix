{
  config,
  pkgs,
  ...
}:

let
  nvimConfigDir = "${config.xdg.configHome}/nvim";
in
{
  stylix.targets.neovim.enable = false;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
  };

  home.sessionVariables = {
    SYSINIT_NVIM_NIX_MANAGED = "true";
    SYSINIT_NVIM_COLORS = builtins.toJSON (builtins.toJSON {
      inherit (config.sysinit.theme) appearance;
      inherit (config.sysinit.theme) colorscheme;
      inherit (config.sysinit.theme) transparency;
      inherit (config.sysinit.theme) variant;
    });
  };

  # The nvim config changes a lot, and I manage plugins through lazy.nvim
  # As a result, it's easier to just manage it seperately as a local directory
  home.activation.setupNeovimConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${nvimConfigDir}
  '';
}
