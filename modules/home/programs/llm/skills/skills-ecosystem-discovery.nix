{ pkgs, lib }:

let
  upstream = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/vercel-labs/skills/c99a72b371b5b4da865f5afa87c5a686f3a46766/skills/find-skills/SKILL.md";
    hash = "sha256-HoX2+WhuFFrKShJOO3BLm76pqofghRXB41Lu5w9ubno=";
  };

  full = builtins.readFile upstream;

  # Strip the YAML frontmatter. The upstream file starts with '---\n', then
  # the frontmatter body, then '---\n', then the skill body. We strip the
  # leading delimiter, split on the closing one, and take the tail.
  withoutLead =
    if lib.hasPrefix "---\n" full then
      lib.substring 4 (builtins.stringLength full) full
    else
      throw "skills-ecosystem-discovery: upstream SKILL.md does not start with '---'";

  parts = builtins.split "\n---\n" withoutLead;
  stripped =
    if builtins.length parts < 3 then
      throw "skills-ecosystem-discovery: upstream SKILL.md missing closing '---' frontmatter delimiter"
    else
      # builtins.split returns [pre, [groups], post]. Take element 2 (post).
      builtins.elemAt parts 2;
in
stripped
