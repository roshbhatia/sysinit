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
        features.atuin
        features.bash
        features.bat
        features.direnv
        features.editorconfig
        features.eza
        features.fd
        features.fzf
        features.git
        features.helix
        features.hushlogin
        features.ere
        features.nix
        features.nixYourShell
        features.omp
        features.openssh
        features.taskwarrior
        ./utils
        features.vivid
        features.zoxide
        features.zsh
      ];

      dev = [
        features.astGrep
        features.bottom
        features.completions
        features.changes
        features.github
        features.gitAi
        features.hunk
        features.htop
        features.java
        features.k9s
        features.kubectl
        ./llm
        features.mise
        features.neovim
        features.nh
        features.nushell
        features.otelCollector
        features.otelTui
        features.queue
        features.seshy
        features.tether
        features.terraform
        features.traces
        features.yazi
      ];

      workstation = [
        features.fastfetch
        features.mail
        features.wezterm
      ];
    }
    ++ lib.optional theme features.theme;
}
