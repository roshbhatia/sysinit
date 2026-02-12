{
  pkgs,
  ...
}:

let
  localSkillContent = import ./skills;

  localSkills = builtins.mapAttrs (
    name: skill: pkgs.writeText "skill-${name}-SKILL.md" skill.content
  ) localSkillContent;

  localSkillDescriptions = builtins.mapAttrs (_name: skill: skill.description) localSkillContent;

  allSkills = localSkills;

  # Generate home.file entries to install skills to a directory
  # Returns an attrset suitable for home.file or xdg.configFile
  installSkillsTo = _basePath: builtins.mapAttrs (_name: path: { source = path; }) allSkills;
in
{
  inherit
    allSkills
    localSkillDescriptions
    installSkillsTo
    ;
}
