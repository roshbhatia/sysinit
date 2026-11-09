{ lib, root }:
let
  frontmatter = import ./frontmatter.nix { inherit lib; };
  sharedDir = root + "/_shared";
  extraFiles =
    name:
    let
      dir = root + "/${name}";
      files = lib.filter (file: file != dir + "/SKILL.md") (lib.filesystem.listFilesRecursive dir);
    in
    lib.listToAttrs (
      map (file: lib.nameValuePair (lib.removePrefix "${toString dir}/" (toString file)) file) files
    );

  mkSkill =
    name: _:
    let
      parsed = frontmatter.parse name (builtins.readFile (root + "/${name}/SKILL.md"));
      a = parsed.attrs;
      files = extraFiles name;
      supported = [
        "name"
        "description"
        "allowed-tools"
        "when_to_use"
        "model"
        "effort"
        "disable-model-invocation"
      ];
      unknown = lib.subtractLists supported (builtins.attrNames a);
    in
    assert lib.assertMsg (
      builtins.stringLength name <= 64 && builtins.match "[a-z0-9]+(-[a-z0-9]+)*" name != null
    ) "skill '${name}': invalid directory name";
    assert lib.assertMsg (unknown == [ ])
      "skill '${name}': unsupported metadata ${lib.concatStringsSep ", " unknown}; use flat supported fields";
    assert lib.assertMsg (
      !(a ? name) || a.name == name
    ) "skill '${name}': name must match its directory";
    assert lib.assertMsg (
      builtins.isString a.description
      && a.description != ""
      && builtins.stringLength a.description <= 1024
    ) "skill '${name}': description must be a nonempty string up to 1024 characters";
    assert lib.assertMsg (
      !(a ? "disable-model-invocation") || builtins.isBool a."disable-model-invocation"
    ) "skill '${name}': disable-model-invocation must be boolean";
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
{
  load = mkSkill;
}
