{
  config,
  pkgs,
  ...
}:

let
  nvimConfigRepo = "git@github.com:roshbhatia/sysinit.nvim.git";
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
    export PATH="${pkgs.git}/bin:${pkgs.openssh}/bin:$PATH"
    export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519_personal -o IdentitiesOnly=yes -o StrictHostKeyChecking=no"

    if [ ! -d "${nvimConfigDir}" ]; then
      ${pkgs.git}/bin/git clone ${nvimConfigRepo} ${nvimConfigDir} || echo "Warning: Failed to clone Neovim config"
    elif [ -d "${nvimConfigDir}/.git" ]; then
      (
        cd ${nvimConfigDir}
        ${pkgs.git}/bin/git remote set-url origin ${nvimConfigRepo}
        ${pkgs.git}/bin/git stash --quiet 2>/dev/null || true
        ${pkgs.git}/bin/git fetch origin main
        ${pkgs.git}/bin/git rebase origin/main
        ${pkgs.git}/bin/git stash pop --quiet 2>/dev/null || true
      ) || echo "Warning: Failed to update Neovim config"
    else
      # Directory exists but isn't a git repo, reset it
      rm -rf ${nvimConfigDir}
      ${pkgs.git}/bin/git clone ${nvimConfigRepo} ${nvimConfigDir} || echo "Warning: Failed to reset Neovim config"
    fi
  '';
}
