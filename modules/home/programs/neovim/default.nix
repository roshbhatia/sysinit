{
  config,
  pkgs,
  ...
}:

let
  themeConfig = {
    inherit (config.sysinit.theme) colorscheme;
    inherit (config.sysinit.theme) variant;
    inherit (config.sysinit.theme) appearance;
    inherit (config.sysinit.theme) transparency;
  };

  nvimConfigRepo = "https://github.com/roshbhatia/sysinit.nvim.git";
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

  xdg.configFile = {
    "nvim/theme_config.json".text = builtins.toJSON themeConfig;
  };

  home.sessionVariables = {
    NIX_MANAGED = "true";
  };

  home.activation.setupNeovimConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.git}/bin:$PATH"

    if [ ! -d "${nvimConfigDir}" ]; then
      ${pkgs.git}/bin/git clone ${nvimConfigRepo} ${nvimConfigDir}
    else
      cd ${nvimConfigDir}
      ${pkgs.git}/bin/git pull origin main
    fi
  '';
}
