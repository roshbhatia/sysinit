{
  config,
  pkgs,
  ...
}:

let
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

  home.sessionVariables = {
    SYSINIT_NVIM_NIX_MANAGED = "true";
    SYSINIT_NVIM_COLORSCHEME_FAMILY = toString config.sysinit.theme.colorscheme;
    SYSINIT_NVIM_COLORSCHEME_VARIANT = toString config.sysinit.theme.variant;
    SYSINIT_NVIM_COLORSCHEME_APPEARANCE = toString config.sysinit.theme.appearance;
    SYSINIT_NVIM_TRANSPARENCY = builtins.toJSON config.sysinit.theme.transparency;
  };

  # The nvim config changes a lot, and I manage plugins through lazy.nvim
  # As a result, it's easier to just manage it seperately
  home.activation.setupNeovimConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.git}/bin:$PATH"

    if [ ! -d "${nvimConfigDir}" ]; then
      ${pkgs.git}/bin/git clone ${nvimConfigRepo} ${nvimConfigDir}
    elif [ -d "${nvimConfigDir}/.git" ]; then
      cd ${nvimConfigDir}
      ${pkgs.git}/bin/git pull --rebase origin main
    else
      # Directory exists but isn't a git repo, reset it
      rm -rf ${nvimConfigDir}
      ${pkgs.git}/bin/git clone ${nvimConfigRepo} ${nvimConfigDir}
    fi
  '';
}
