{ pkgs, ... }:
let
  # A rename, not a shim: the owner chose no `wtrun` alias, so this is the only
  # name that resolves. `tool-sources.nix` went with the script it pointed at;
  # nothing else read it, and a source map for zero sources is scaffolding.
  worker = pkgs.writeShellApplication {
    name = "worker";
    runtimeInputs = [
      pkgs.sysinit-agent
      pkgs.wezterm
    ];
    text = ''
      exec sysinit-agent worker "$@"
    '';
  };

  # A shim, not a rename: the pre-commit hook and the citation-verification
  # skill both still spell this `citelock`.
  citelock = pkgs.writeShellApplication {
    name = "citelock";
    runtimeInputs = [
      pkgs.curl
      pkgs.sysinit-agent
    ];
    text = ''
      exec sysinit-agent citelock "$@"
    '';
  };
in
{
  home.packages = [
    citelock
    worker
  ];
}
