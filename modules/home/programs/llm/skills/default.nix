# The skill registry, scanned rather than enumerated.
#
# Each local skill is a directory whose SKILL.md carries flat frontmatter and
# the body. Adding a skill is creating a directory; nothing here needs editing.
# That is the point: a body is prose with no Nix dependency, so a renderer can
# ship it without an eval and an edit can take effect without a rebuild.
#
# Two things are deliberately not directories:
#   _shared/  fragments included by more than one skill, so a block whose
#             purpose is that it cannot drift stays defined once.
#   skills-ecosystem-discovery  upstream content pinned by hash. Inlining it
#             into a SKILL.md would make it hand-editable, which the vendoring
#             rule forbids, so it stays a Nix fetch.
{ pkgs, lib }:

let
  frontmatter = import ../lib/frontmatter.nix { inherit lib; };

  root = ./.;
  sharedDir = root + "/_shared";

  skillDirs = lib.filterAttrs (n: type: type == "directory" && !(lib.hasPrefix "_" n)) (
    builtins.readDir root
  );

  # Files a skill ships beside its SKILL.md, as "<subdir>/<file>" -> path. Two
  # levels is the whole of what any skill uses (references/, scripts/), and a
  # bounded walk throws on a third rather than silently dropping it.
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
    # The file spells it when_to_use, matching what the render emits; the
    # registry has always spelled it whenToUse. Map here so neither side moves.
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
