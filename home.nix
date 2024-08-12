{ config, pkgs, ... }:

let
  username = builtins.getEnv "USER";
  homeDir = builtins.getEnv "HOME";
in
{
  home.username = username;
  home.homeDirectory = homeDir;

  programs.home-manager.enable = true;

  programs.zsh.enable = true;
  programs.git.enable = true;

  # homebrew
  home.activation.installBrewfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f ${./brew/Brewfile} ]; then
      brew bundle --file=${./brew/Brewfile}
    fi
  '';

  # atuin  
  home.file.".config/atuin/config.toml".source = ./atuin/config.toml;

  # macchina
  home.file.".config/machina/themes/nike.ascii".source = ./machina/themes/nike.ascii;
  home.file.".config/machina/themes/nike.toml".source = ./machina/themes/nike.toml;
  home.file.".config/machina/themes/rosh.ascii".source = ./machina/themes/rosh.ascii;
  home.file.".config/machina/themes/rosh.toml".source = ./machina/themes/rosh.toml;

  # starship
  home.file.".config/starship/starship.toml".source = ./starship/starship.toml;

  # iterm2
  home.file.".iterm2/profile.json".source = ./iterm2/profile.json;

  # other utils
  home.file.".zsh/completion-gen.sh".source = /usr/local/bin/completion-gen.sh;
  home.file.".zsh/kellog.sh".source = /usr/local/bin/kellog.sh;
}
