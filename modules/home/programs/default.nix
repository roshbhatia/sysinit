{
  lib,
  profile ? "workstation",
  theme ? true,
  ...
}:
let
  profiles = import ../../shared/profile-tiers.nix { inherit lib; };
  features = lib.mergeAttrsList (
    map (file: (import file).flake.modules.homeManager or { }) (
      import ../../../features/module-exports.nix
    )
  );
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
        features.git
        ./helix.nix
        ./hushlogin.nix
        ./ere.nix
        ./nix.nix
        ./nix-your-shell.nix
        ./omp.nix
        features.openssh
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
        features.nushell
        ./otel-collector.nix
        ./otel-tui.nix
        features.queue
        features.seshy
        features.tether
        ./terraform.nix
        ./traces.nix
        ./yazi
      ];

      workstation = [
        ./fastfetch.nix
        ./mail
        features.wezterm
      ];
    }
    ++ lib.optional theme features.theme;
}
