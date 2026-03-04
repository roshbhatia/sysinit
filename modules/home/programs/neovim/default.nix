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
    SYSINIT_NVIM_COLORS = builtins.toJSON (
      builtins.toJSON {
        inherit (config.sysinit.theme) appearance;
        inherit (config.sysinit.theme) colorscheme;
        inherit (config.sysinit.theme) transparency;
        inherit (config.sysinit.theme) variant;
      }
    );
  };

  # The nvim config changes a lot, and I manage plugins through lazy.nvim
  # As a result, it's easier to just manage it seperately
  home.activation.setupNeovimConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.git}/bin:$PATH"

    if [ ! -d "${nvimConfigDir}" ]; then
      ${pkgs.git}/bin/git clone ${nvimConfigRepo} ${nvimConfigDir}
    elif [ -d "${nvimConfigDir}/.git" ]; then
      cd ${nvimConfigDir}
      ${pkgs.git}/bin/git add -A
      ${pkgs.git}/bin/git diff --cached --quiet || ${pkgs.git}/bin/git commit -m "dirty"
      ${pkgs.git}/bin/git pull --rebase origin main
      ${pkgs.git}/bin/git push origin main
    else
      # Directory exists but isn't a git repo, reset it
      rm -rf ${nvimConfigDir}
      ${pkgs.git}/bin/git clone ${nvimConfigRepo} ${nvimConfigDir}
    fi
  '';
}
