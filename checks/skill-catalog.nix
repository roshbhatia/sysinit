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
  names = builtins.attrNames skills;
  sources = map (name: {
    inherit name;
    path = "${../modules/home/programs/llm/skills}/${name}/SKILL.md";
    claude = false;
  }) names;
  published = lib.concatMap (
    root:
    map (name: {
      inherit name;
      path = home.home.file."${root}/${name}/SKILL.md".source;
      claude = root == ".claude/skills";
    }) names
  ) roots;
  rejected =
    name: !(builtins.tryEval (builtins.deepSeq (package.load name "directory") true)).success;
  manifest = pkgs.writeText "skill-contracts.json" (
    builtins.toJSON {
      frontmatterFiles = sources ++ published;
      packages = lib.mapAttrsToList (name: skill: {
        inherit name;
        inherit (skill) content;
        files = builtins.attrNames (skill.files or { });
      }) skills;
      cases = builtins.fromJSON (builtins.readFile ../docs/skill-routing-cases.json);
      inherit names;
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
assert fixture.metadata.sysinit-claude-disable-model-invocation == "false";
assert fixture.files ? "data.json";
assert fixture.files ? "references/nested/details.md";
assert fixture.files ? "scripts/probe.nu";
assert !(fixture.files ? "SKILL.md");
import ./native.nix { inherit pkgs; } {
  name = "skill-catalog";
  inputs = [ pkgs.git ];
  commands = [
    [
      "nu"
      "--no-config-file"
      ./skill-catalog.nu
      manifest
    ]
    [
      "nu"
      "--no-config-file"
      ./host-state.nu
      ../modules/home/programs/llm/skills/nix-deployment/scripts/host-state.nu
    ]
    [
      "nu"
      "--no-config-file"
      ./skill-helpers.nu
      ../modules/home/programs/llm/skills/skills-ecosystem-discovery/scripts/catalog.nu
    ]
  ];
}
