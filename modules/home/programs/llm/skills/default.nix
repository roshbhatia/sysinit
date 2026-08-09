{ pkgs, lib }:

let
  frontmatter = import ../lib/frontmatter.nix { inherit lib; };

  root = ./.;
  sharedDir = root + "/_shared";

  # Directories here that are NOT skills. A directory can hold a tool's source
  # without advertising that tool to an agent.
  #
  # `wtrun` drives a WezTerm pane. It stays on the owner's PATH through
  # skill-tools.nix, which reads wtrun/wtrun.sh directly and does not go through
  # this registry. What excluding it removes is the advertisement: no rendered
  # SKILL.md, so no description telling an agent to reach for it and no
  # `allowed-tools` grant pre-approving it.
  #
  # This is not a fence and is not meant as one. Any harness with a Bash tool can
  # drive a pane through the wezterm CLI directly, and this repository cannot
  # prevent that. Removing the advertisement is the largest reduction available.
  #
  # The wording above is deliberate and the gate at task 2.9 is why: that gate
  # requires the pane-driving command names to appear in exactly three files, so
  # spelling one out in a comment here fails it. A comment is not a caller, and a
  # gate that cannot tell them apart is the one we have.
  notSkills = [ "wtrun" ];

  skillDirs = lib.filterAttrs (
    n: type: type == "directory" && !(lib.hasPrefix "_" n) && !(builtins.elem n notSkills)
  ) (builtins.readDir root);

  extraFiles =
    name:
    let
      dir = root + "/${name}";
      subdirs = lib.filterAttrs (_: t: t == "directory") (builtins.readDir dir);
      inSub =
        sub:
        let
          entries = builtins.readDir (dir + "/${sub}");
        in
        if lib.filterAttrs (_: t: t == "directory") entries != { } then
          throw "skill '${name}': ${sub}/ nests a directory; a skill ships at most two levels"
        else
          lib.mapAttrs' (f: _: lib.nameValuePair "${sub}/${f}" (dir + "/${sub}/${f}")) entries;
    in
    lib.foldlAttrs (
      acc: sub: _:
      acc // inSub sub
    ) { } subdirs;

  mkSkill =
    name: _:
    let
      parsed = frontmatter.parse name (builtins.readFile (root + "/${name}/SKILL.md"));
      a = parsed.attrs;
      files = extraFiles name;
    in
    {
      inherit (a) description;
      content = frontmatter.expandIncludes { inherit name sharedDir; } parsed.body;
    }
    // lib.optionalAttrs (a ? "allowed-tools") { "allowed-tools" = a."allowed-tools"; }
    // lib.optionalAttrs (a ? when_to_use) { whenToUse = a.when_to_use; }
    // lib.optionalAttrs (a ? model) { inherit (a) model; }
    // lib.optionalAttrs (a ? effort) { inherit (a) effort; }
    // lib.optionalAttrs (a ? "disable-model-invocation") {
      "disable-model-invocation" = a."disable-model-invocation";
    }
    // lib.optionalAttrs (files != { }) { inherit files; };
in
lib.mapAttrs mkSkill skillDirs
// {
  skills-ecosystem-discovery = {
    description = "Discovers and installs agent skills from the open skills ecosystem at skills.sh. Use when the user asks 'how do I do X', 'is there a skill for X', wants to extend agent capabilities, or wants to install something via npx skills.";
    content = import ./skills-ecosystem-discovery.nix { inherit pkgs lib; };
    allowed-tools = "Bash(npx:*) WebFetch";
  };
}
