{
  lib,
  profile ? "workstation",
  theme ? true,
  ...
}:
let
  profiles = import ../../shared/profile-tiers.nix { inherit lib; };
in
{
  imports =
    profiles.forProfile profile {
      minimal = [
        ./bash.nix
        ./bat.nix
        ./direnv.nix
        ./editorconfig.nix
        ./eza.nix
        ./fd.nix
        ./fzf.nix
        ./git
        ./helix.nix
        ./hushlogin.nix
        ./nix.nix
        ./nix-your-shell.nix
        ./omp.nix
        ./ssh.nix
        ./utils
        ./vivid.nix
        ./zmx
        ./zoxide.nix
        ./zsh
      ];

      dev = [
        ./ast-grep
        ./bottom.nix
        ./gh.nix
        ./htop.nix
        ./k9s.nix
        ./kubectl.nix
        ./llm
        ./mise.nix
        ./neovim
        ./nh.nix
        ./nushell.nix
        ./otel-tui.nix
        ./seshy
        ./yazi
      ];

      workstation = [
        ./fastfetch.nix
        ./wezterm
      ];
    }
    ++ lib.optional theme ../stylix-targets.nix;
}
