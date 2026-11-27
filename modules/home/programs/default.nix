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
        ./atuin.nix
        ./bash.nix
        ./bat.nix
        ./direnv.nix
        ./editorconfig.nix
        ./eza.nix
        ./fd.nix
        ./fzf.nix
        ../../../features/git/home.nix
        ./helix.nix
        ./hushlogin.nix
        ./ere.nix
        ./nix.nix
        ./nix-your-shell.nix
        ./omp.nix
        ../../../features/ssh/home.nix
        ./taskwarrior.nix
        ./utils
        ./vivid.nix
        ./zoxide.nix
        ./zsh
      ];

      dev = [
        ./ast-grep
        ./bottom.nix
        ./completions
        ./changes.nix
        ./gh.nix
        ./git-ai
        ./hunk.nix
        ./htop.nix
        ./java.nix
        ./k9s.nix
        ./kubectl.nix
        ./llm
        ./mise.nix
        ./neovim
        ./nh.nix
        ../../../features/nushell/home.nix
        ./otel-collector.nix
        ./otel-tui.nix
        ../../../features/queue/home.nix
        ../../../features/seshy/home.nix
        ../../../features/tether/home.nix
        ./terraform.nix
        ./traces.nix
        ./yazi
      ];

      workstation = [
        ./fastfetch.nix
        ./mail
        ../../../features/wezterm/home.nix
      ];
    }
    ++ lib.optional theme ../../../features/theme/home.nix;
}
