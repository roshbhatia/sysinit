{
  pkgs,
  lib ? pkgs.lib,
  ...
}:

let
  registry = import ./skills;

  requiredSkills = [
    "shell-scripting"
    "openspec-propose"
    "openspec-apply"
    "openspec-explore"
    "openspec-archive"
    "find-skills"
    "seshy"
    "cocoindex-query"
  ];

  disallowedFields = [
    "license"
    "compatibility"
    "version"
    "metadata"
    "author"
    "generatedBy"
  ];

  bannedDescriptionStartPrefixes = [
    "I "
    "I'll"
    "I'm "
    "I will"
    "My "
    "We "
    "You should"
  ];

  bannedDescriptionSubstrings = [
    "ALWAYS"
    "NEVER"
  ];

  allowedExtraKeys = [
    "description"
    "content"
    "allowed-tools"
    "whenToUse"
    "skip"
  ];

  validateRegistryKeys =
    name: skill:
    let
      keys = builtins.attrNames skill;
      legacy = builtins.filter (k: builtins.elem k disallowedFields) keys;
      unknown = builtins.filter (k: !(builtins.elem k allowedExtraKeys)) keys;
    in
    if legacy != [ ] then
      throw "skill '${name}': disallowed legacy frontmatter field(s) in registry entry: ${builtins.concatStringsSep ", " legacy}"
    else if unknown != [ ] then
      throw "skill '${name}': unknown registry key(s): ${builtins.concatStringsSep ", " unknown}"
    else
      true;

  validateName =
    name:
    let
      matched = builtins.match "[a-z0-9-]+" name;
      lenOk = builtins.stringLength name >= 1 && builtins.stringLength name <= 64;
      hasClaude = lib.hasInfix "claude" name;
      hasAnthropic = lib.hasInfix "anthropic" name;
    in
    if matched == null || !lenOk then
      throw "skill name '${name}' does not match ^[a-z0-9-]{1,64}$"
    else if hasClaude then
      throw "skill name '${name}' contains forbidden substring 'claude'"
    else if hasAnthropic then
      throw "skill name '${name}' contains forbidden substring 'anthropic'"
    else
      true;

  validateDescription =
    name: desc:
    let
      len = builtins.stringLength desc;
      startViolations = builtins.filter (p: lib.hasPrefix p desc) bannedDescriptionStartPrefixes;
      substringViolations = builtins.filter (p: lib.hasInfix p desc) bannedDescriptionSubstrings;
    in
    if len < 1 then
      throw "skill '${name}': description is empty"
    else if len > 1024 then
      throw "skill '${name}': description exceeds 1024 chars (got ${toString len})"
    else if startViolations != [ ] then
      throw "skill '${name}': description must not start with first-person voice (${builtins.concatStringsSep ", " startViolations})"
    else if substringViolations != [ ] then
      throw "skill '${name}': description contains banned imperative(s): ${builtins.concatStringsSep ", " substringViolations}"
    else
      true;

  countLines =
    s:
    let
      parts = builtins.split "\n" s;
      stringParts = builtins.filter builtins.isString parts;
    in
    builtins.length stringParts;

  validateBody =
    name: body:
    let
      lines = countLines body;
    in
    if lines > 500 then
      throw "skill '${name}': body exceeds 500 lines (got ${toString lines})"
    else
      true;

  validateAllowedTools =
    name: at:
    let
      patterns = lib.filter (p: p != "") (lib.splitString " " at);
      isSimple = p: builtins.match "[A-Z][A-Za-z]*" p != null;
      isBashGlob = p: builtins.match "Bash\\([a-z][a-z0-9_-]*:\\*\\)" p != null;
      isMcp = p: builtins.match "[A-Z][A-Za-z0-9_]*:[a-z_*]+" p != null;
      validPattern = p: isSimple p || isBashGlob p || isMcp p;
      invalid = builtins.filter (p: !(validPattern p)) patterns;
    in
    if invalid != [ ] then
      throw "skill '${name}': malformed allowed-tools pattern(s): ${builtins.concatStringsSep ", " invalid}"
    else
      true;

  missingRequired = builtins.filter (n: !(builtins.hasAttr n registry)) requiredSkills;

  _requiredCheck =
    if missingRequired != [ ] then
      throw "Required skills missing from registry: ${builtins.concatStringsSep ", " missingRequired}"
    else
      true;

  renderSkill =
    name: skill:
    let
      _ck = validateRegistryKeys name skill;
      _nk = validateName name;
      _dk = validateDescription name skill.description;
      _bk = validateBody name skill.content;
      _ak = if skill ? "allowed-tools" then validateAllowedTools name skill."allowed-tools" else true;

      frontmatterLines = [
        "---"
        "name: ${name}"
        "description: ${skill.description}"
      ]
      ++ lib.optional (skill ? "allowed-tools") "allowed-tools: ${skill."allowed-tools"}"
      ++ lib.optional (skill ? whenToUse) "when_to_use: ${skill.whenToUse}"
      ++ [
        "---"
        ""
      ];

      frontmatter = builtins.concatStringsSep "\n" frontmatterLines + "\n";

      forced = builtins.deepSeq [
        _ck
        _nk
        _dk
        _bk
        _ak
        _requiredCheck
      ] (frontmatter + skill.content);
    in
    forced;

  localSkills = builtins.mapAttrs (
    name: skill: pkgs.writeText "skill-${name}-SKILL.md" (renderSkill name skill)
  ) registry;

  localSkillDescriptions = builtins.mapAttrs (_name: skill: skill.description) registry;

  allSkills = localSkills;

  installSkillsTo = _basePath: builtins.mapAttrs (_name: path: { source = path; }) allSkills;
in
{
  inherit
    allSkills
    localSkillDescriptions
    installSkillsTo
    ;
}
