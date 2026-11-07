{ pkgs }:
let
  module = import ../modules/home/programs/ast-grep {
    inherit pkgs;
    inherit (pkgs) lib;
    config.xdg.configHome = "\${TMPDIR}/config";
  };
  configuration = pkgs.writeText "sgconfig.yml" module.xdg.configFile."ast-grep/sgconfig.yml".text;
  wrapper = builtins.head module.home.packages;
in
pkgs.runCommand "ast-grep-installed-rules" { } ''
  mkdir -p "$TMPDIR/config/ast-grep" fixture
  ln -s ${configuration} "$TMPDIR/config/ast-grep/sgconfig.yml"
  ln -s ${../modules/home/programs/ast-grep/rules} "$TMPDIR/config/ast-grep/rules"
  printf '%s\n' 'builtins.currentTime' > fixture/impure.nix
  status=0
  ${wrapper}/bin/sgg --json fixture > findings.json || status=$?
  test "$status" -eq 1
  ${pkgs.jq}/bin/jq -e 'any(.[]; .ruleId == "nix-impure-eval")' findings.json
  printf '%s\n' '{ answer = 42; }' > fixture/impure.nix
  ${wrapper}/bin/sgg fixture
  touch "$out"
''
