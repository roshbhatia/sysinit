{ pkgs }:
let
  module = import ../../modules/home/programs/ast-grep {
    inherit pkgs;
    inherit (pkgs) lib;
    config.xdg.configHome = "\${TMPDIR}/config";
  };
  configuration = pkgs.writeText "sgconfig.yml" module.xdg.configFile."ast-grep/sgconfig.yml".text;
  wrapper = builtins.head module.home.packages;
in
import ../lib/nushell.nix { inherit pkgs; } {
  name = "ast-grep-installed-rules";
  script = ./ast-grep.nu;
  sources = [ ../lib/process.nu ];
  arguments = [
    configuration
    ../../modules/home/programs/ast-grep/rules
    "${wrapper}/bin/sgg"
  ];
}
