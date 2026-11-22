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
        "license"
        "compatibility"
        "metadata"
        "allowed-tools"
      ];
      unknown = lib.subtractLists supported (builtins.attrNames a);
      metadata = a.metadata or { };
    in
    assert lib.assertMsg (
      builtins.stringLength name <= 64 && builtins.match "[a-z0-9]+(-[a-z0-9]+)*" name != null
    ) "skill '${name}': invalid directory name";
    assert lib.assertMsg (
      unknown == [ ]
    ) "skill '${name}': unsupported frontmatter fields ${lib.concatStringsSep ", " unknown}";
    assert lib.assertMsg ((a.name or null) == name) "skill '${name}': name must match its directory";
    assert lib.assertMsg (
      builtins.isString (a.description or null)
      && lib.trim a.description != ""
      && builtins.stringLength a.description <= 1024
    ) "skill '${name}': description must be a nonempty string up to 1024 characters";
    assert lib.assertMsg (
      !(a ? compatibility)
      || (
        builtins.isString a.compatibility
        && lib.trim a.compatibility != ""
        && builtins.stringLength a.compatibility <= 500
      )
    ) "skill '${name}': compatibility must be a nonempty string up to 500 characters";
    assert lib.assertMsg (lib.all (key: !(a ? ${key}) || builtins.isString a.${key}) [
      "license"
      "allowed-tools"
    ]) "skill '${name}': license and allowed-tools must be strings";
    assert lib.assertMsg (
      builtins.isAttrs metadata && lib.all builtins.isString (builtins.attrValues metadata)
    ) "skill '${name}': metadata must map strings to strings";
    assert lib.assertMsg (
      !(metadata ? sysinit-claude-disable-model-invocation)
      || builtins.elem metadata.sysinit-claude-disable-model-invocation [
        "true"
        "false"
      ]
    ) "skill '${name}': sysinit-claude-disable-model-invocation must be a boolean string";
    {
      inherit (a) description;
      content = frontmatter.expandIncludes { inherit name sharedDir; } parsed.body;
    }
    // lib.getAttrs (lib.intersectLists (builtins.attrNames a) [
      "license"
      "compatibility"
      "metadata"
      "allowed-tools"
    ]) a
    // lib.optionalAttrs (files != { }) { inherit files; };
in
{
  load = mkSkill;
}
