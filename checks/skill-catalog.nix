{ pkgs, home }:
let
  inherit (pkgs) lib;
  package = import ../modules/home/programs/llm/lib/skill-package.nix {
    inherit lib;
    root = ./fixtures/skills;
  };
  fixture = package.load "contract-fixture" "directory";
  renderer = import ../modules/home/programs/llm/skills/render.nix { inherit pkgs; };
  registry = import ../modules/home/programs/llm/harnesses/registry.nix;
  skills = import ../modules/home/programs/llm/skills { inherit lib; };
  roots = lib.unique (map (h: h.skillRoot) (builtins.attrValues registry));
  paths = lib.concatMap (
    root: map (name: home.home.file."${root}/${name}/SKILL.md".source) (builtins.attrNames skills)
  ) roots;
  rejected =
    name: !(builtins.tryEval (builtins.deepSeq (package.load name "directory") true)).success;
  manifest = pkgs.writeText "skill-contracts.json" (
    builtins.toJSON {
      inherit paths;
      packages = lib.mapAttrsToList (name: skill: {
        inherit name;
        inherit (skill) content;
        files = builtins.attrNames (skill.files or { });
      }) skills;
      cases = builtins.fromJSON (builtins.readFile ../docs/skill-routing-cases.json);
      names = builtins.attrNames skills;
      guidance = builtins.readFile ../AGENTS.md;
      fixtureFiles = builtins.attrValues fixture.files;
      rendered = renderer.renderSkill "claude" "contract-fixture" fixture;
      amp = renderer.renderSkill "amp" "contract-fixture" fixture;
    }
  );
in
assert rejected "invalid-metadata";
assert rejected "invalid-boolean";
assert fixture.description == "It's a fixture";
assert fixture."disable-model-invocation" == false;
assert fixture.files ? "data.json";
assert fixture.files ? "references/nested/details.md";
assert fixture.files ? "scripts/probe.py";
assert !(fixture.files ? "SKILL.md");
pkgs.runCommand "skill-catalog"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.git
    ];
  }
  ''
    python3 ${./skill-catalog.py} ${manifest}
    python3 ${./skill-helpers.py} \
      ${../modules/home/programs/llm/skills/nix-deployment/scripts/host-state.py} \
      ${../modules/home/programs/llm/skills/skills-ecosystem-discovery/scripts/catalog.py}
    touch "$out"
  ''
