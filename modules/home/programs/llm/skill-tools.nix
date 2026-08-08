{ pkgs, ... }:
let
  sources = import ./skills/tool-sources.nix;
  sourceOf = name: ./skills + "/${sources.${name}}";

  wtrun = pkgs.writeShellApplication {
    name = "wtrun";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.jq
      pkgs.wezterm
    ];
    text = builtins.readFile (sourceOf "wtrun");
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
    wtrun
  ];
}
