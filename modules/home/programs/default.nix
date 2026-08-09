{
  lib,
  profile ? "workstation",
  ...
}:
# Which program modules this host imports, chosen by what the host is for.
#
# `profile` is a function argument and not `config.sysinit.profiles.*`, and it
# has to be: `imports` is resolved before `config` exists, so reading the option
# here would be infinite recursion. Wrapping each module in `lib.mkIf` would
# avoid the recursion and defeat the point, since the module would still be
# imported and evaluated with only its output discarded.
# `modules/shared/options/profiles.nix` carries the full reasoning.
#
# The list keeps its original order and is filtered, rather than being written
# as one list per tier and concatenated. Order is not cosmetic here: a module's
# position feeds list-valued options downstream, so regrouping would change the
# derivation without changing what is installed.
let
  profiles = import ../../shared/profile-tiers.nix { inherit lib; };

  # The lowest tier that needs each module.
  #
  #   minimal      what a box reached over ssh needs to be usable at all
  #   dev          toolchains, the agent runtime, and the session substrate
  #   workstation  what only makes sense in front of a screen
  modules = [
    {
      tier = "dev";
      path = ./ast-grep;
    }
    {
      tier = "minimal";
      path = ./bash.nix;
    }
    {
      tier = "minimal";
      path = ./bat.nix;
    }
    {
      tier = "dev";
      path = ./bottom.nix;
    }
    {
      tier = "minimal";
      path = ./direnv.nix;
    }
    {
      tier = "minimal";
      path = ./editorconfig.nix;
    }
    {
      tier = "minimal";
      path = ./eza.nix;
    }
    {
      tier = "workstation";
      path = ./fastfetch.nix;
    }
    {
      tier = "minimal";
      path = ./fd.nix;
    }
    {
      tier = "minimal";
      path = ./fzf.nix;
    }
    {
      tier = "dev";
      path = ./gh.nix;
    }
    {
      tier = "minimal";
      path = ./git;
    }
    # The editor a minimal box gets: one binary, no plugin tree, so it works on
    # a machine this repository was pulled onto ten minutes ago.
    {
      tier = "minimal";
      path = ./helix.nix;
    }
    {
      tier = "dev";
      path = ./htop.nix;
    }
    {
      tier = "dev";
      path = ./hunk.nix;
    }
    {
      tier = "minimal";
      path = ./hushlogin.nix;
    }
    {
      tier = "dev";
      path = ./k9s.nix;
    }
    {
      tier = "dev";
      path = ./kubectl.nix;
    }
    {
      tier = "dev";
      path = ./mise.nix;
    }
    {
      tier = "dev";
      path = ./llm;
    }
    {
      tier = "dev";
      path = ./neovim;
    }
    {
      tier = "dev";
      path = ./nh.nix;
    }
    {
      tier = "minimal";
      path = ./nix.nix;
    }
    {
      tier = "minimal";
      path = ./nix-your-shell.nix;
    }
    {
      tier = "dev";
      path = ./nushell.nix;
    }
    {
      tier = "minimal";
      path = ./omp.nix;
    }
    {
      tier = "dev";
      path = ./seshy;
    }
    {
      tier = "minimal";
      path = ./ssh.nix;
    }
    {
      tier = "dev";
      path = ./tmux.nix;
    }
    {
      tier = "minimal";
      path = ./utils;
    }
    {
      tier = "minimal";
      path = ./vivid.nix;
    }
    {
      tier = "workstation";
      path = ./wezterm;
    }
    {
      tier = "dev";
      path = ./yazi;
    }
    {
      tier = "minimal";
      path = ./zoxide.nix;
    }
    {
      tier = "minimal";
      path = ./zsh;
    }
  ];
in
{
  imports = map (module: module.path) (
    lib.filter (module: profiles.atLeast profile module.tier) modules
  );
}
