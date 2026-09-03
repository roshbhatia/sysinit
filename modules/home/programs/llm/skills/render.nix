{
  pkgs,
  lib ? pkgs.lib,
  ...
}:

let
  registry = import ./. { inherit pkgs lib; };
  vocab = import ../lib/vocab.nix { inherit lib; };
  frontmatter = import ../lib/frontmatter.nix { inherit lib; };

  # Name and description are the one level of a skill that is always in the system
  # prompt, so this budget is spent on every session that never loads the skill.
  # The largest description here is 489 chars, so the cap binds on the next one
  # that grows rather than after it has already shipped.

  normativePreamble = ''
    > Normative keywords follow [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119); "never" is MUST NOT, "always" is MUST, "prefer" is SHOULD.

  '';

  renderSkill =
    harness: name: skill:
    let
      metadata = {
        inherit name;
        inherit (skill) description;
        allowed-tools = skill."allowed-tools" or null;
        when_to_use = skill.whenToUse or null;
        model = if skill ? model && harness == "claude" then skill.model else null;
        effort = if skill ? effort && harness == "claude" then skill.effort else null;
        disable-model-invocation = if skill ? "disable-model-invocation" then true else null;
      };
    in
    vocab.applyVocab harness ''
      ${frontmatter.render metadata}
      ${normativePreamble}${skill.content}
    '';

  renderSkillsFor =
    harness:
    builtins.mapAttrs (
      name: skill: pkgs.writeText "skill-${harness}-${name}-SKILL.md" (renderSkill harness name skill)
    ) registry;

  localSkills = renderSkillsFor "claude";
  ampSkills = renderSkillsFor "amp";

  localSkillDescriptions = builtins.mapAttrs (_name: skill: skill.description) registry;

  allSkills = localSkills;

  skillExtraFiles = lib.foldlAttrs (
    acc: name: skill:
    acc // (lib.mapAttrs' (rel: src: lib.nameValuePair "${name}/${rel}" src) (skill.files or { }))
  ) { } registry;

  installSkillsTo = _basePath: builtins.mapAttrs (_name: path: { source = path; }) allSkills;
in
{
  inherit
    allSkills
    ampSkills
    localSkillDescriptions
    skillExtraFiles
    installSkillsTo
    ;
}
