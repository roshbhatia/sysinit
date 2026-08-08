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

  citelock = pkgs.writeShellScriptBin "citelock" (builtins.readFile (sourceOf "citelock"));
in
{
  home.packages = [
    citelock
    wtrun
  ];
}
