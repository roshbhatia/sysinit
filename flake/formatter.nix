{ pkgs }:
pkgs.writeShellApplication {
  name = "sysinit-fmt";
  runtimeInputs = with pkgs; [
    git
    treefmt
    nixfmt
    shfmt
    stylua
    go
    ruff
    nufmt
    fish
    taplo
    prettier
    clang-tools
    cue
    nushell
  ];
  text = ''
    exec nu --no-config-file ${../hack/format.nu} "$@"
  '';
}
