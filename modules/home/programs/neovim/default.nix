{
  config,
  pkgs,
  ...
}:

let
  themeConfig = {
    colorscheme = config.sysinit.theme.colorscheme;
    variant = config.sysinit.theme.variant;
    appearance = config.sysinit.theme.appearance;
    transparency = config.sysinit.theme.transparency;
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

    initLua = ''
      -- Injected by home-manager
      vim.env.NIX_MANAGED = true
    '';
  };

  xdg.configFile = {
    "nvim/theme_config.json".text = builtins.toJSON themeConfig;
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
