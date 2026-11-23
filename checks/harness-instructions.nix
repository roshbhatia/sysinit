{
  lib,
  pkgs,
  home,
}:
let
  instructions = import ../modules/home/programs/llm/lib/instructions.nix { inherit lib; };
  registry = import ../modules/home/programs/llm/harnesses/registry.nix;
  harnesses = builtins.attrNames registry;
  skills = import ../modules/home/programs/llm/skills/render.nix {
    inherit pkgs;
    inherit (home.sysinit.llm) enabledOptInSkills;
  };
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
          skillsRoot = "~/${h.skillRoot}";
          localSkillDescriptions =
            skills.localSkillDescriptions // home.sysinit.llm.instructions.additionalSkillDescriptions;
          extraSections = home.sysinit.llm.instructions.extraSections;
          skillRoutes = home.sysinit.llm.instructions.skillRoutes;
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
pkgs.runCommand "harness-instructions" { nativeBuildInputs = [ pkgs.nushell ]; } ''
  nu --no-config-file ${./harness-instructions.nu} ${manifest}
  touch $out
''
