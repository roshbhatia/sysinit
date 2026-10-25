{
  lib,
  pkgs,
  home,
}:
let
  instructions = import ../modules/home/programs/llm/lib/instructions.nix { inherit lib; };
  registry = import ../modules/home/programs/llm/harnesses/registry.nix;
  harnesses = builtins.attrNames registry;
  skills = import ../modules/home/programs/llm/skills/render.nix { inherit pkgs; };
  render =
    renderer: harness:
    renderer {
      inherit harness;
      localSkillDescriptions = { };
    };
  base = map (render instructions.makeInstructions) harnesses;
  styled = map (render instructions.makeInstructionsWithStyle) harnesses;
  withoutOrc = text: !(lib.hasInfix "Orc" text) && !(lib.hasInfix "ORC_" text);
  style = instructions.outputStyle;
  hasStyleOnce = text: builtins.length (lib.splitString style.rules text) == 2;
  claudeStyle = home.home.file.".claude/output-styles/${style.name}.md".text;
  homePath = path: lib.removePrefix "${home.home.homeDirectory}/" (lib.removePrefix "~/" path);
  instructionFile =
    path:
    let
      file = lib.findFirst (f: homePath f.target == homePath path) null (
        builtins.attrValues home.home.file
      );
    in
    assert lib.assertMsg (file != null) "No generated instruction file for ${path}";
    file.source;
  actualInstructions = lib.mapAttrsToList (name: h: {
    inherit name;
    key = h.contextKey or [ ];
    source =
      if (h.contextKey or [ ]) == [ ] then
        instructionFile h.context
      else
        pkgs.writeText "${name}-instruction-config.json" (
          builtins.toJSON home.sysinit.llm.managedFiles.${name}.content
        );
    expected = pkgs.writeText "${name}-expected-instructions.md" (
      (if h ? contextStyle then instructions.makeInstructions else instructions.makeInstructionsWithStyle)
        {
          harness = name;
          skillsRoot = "~/.claude/skills";
          inherit (skills) localSkillDescriptions;
          extraSections = home.sysinit.llm.instructions.extraSections;
        }
    );
    style = if h ? contextStyle then instructionFile h.contextStyle else null;
  }) registry;
  manifest = pkgs.writeText "harness-instructions.json" (
    builtins.toJSON {
      harnesses = actualInstructions;
      outputStyle = style.rules;
    }
  );
in
assert lib.all withoutOrc base;
assert lib.all withoutOrc styled;
assert lib.all hasStyleOnce styled;
assert lib.all (text: !(lib.hasInfix style.rules text)) base;
assert hasStyleOnce claudeStyle;
assert lib.hasInfix "keep-coding-instructions: true\n---" claudeStyle;
assert home.programs.claude-code.settings.outputStyle == style.name;
pkgs.runCommand "harness-instructions" { } ''
  ${pkgs.python3}/bin/python - ${manifest} <<'PY'
  import json
  import pathlib
  import sys

  manifest = json.loads(pathlib.Path(sys.argv[1]).read_text())
  for harness in manifest["harnesses"]:
      text = pathlib.Path(harness["source"]).read_text()
      if harness["key"]:
          value = json.loads(text)
          for key in harness["key"]:
              value = value[key]
          text = value
      expected = pathlib.Path(harness["expected"]).read_text()
      assert text.count(expected) == 1, harness["name"]
      if harness["style"]:
          text = pathlib.Path(harness["style"]).read_text()
          assert text.count(manifest["outputStyle"]) == 1, harness["name"]
      print(harness["name"], "generated instructions match shared sources")
  PY
  touch $out
''
