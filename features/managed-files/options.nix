{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  imports = [
    (lib.mkAliasOptionModule [ "sysinit" "llm" "managedFiles" ] [ "sysinit" "managedFiles" ])
  ];

  options.sysinit.managedFiles = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Per-file kill switch. When false the target is neither read nor
              written, so one misbehaving harness is disabled without
              reverting the others.
            '';
          };
          path = mkOption {
            type = types.str;
            description = "Target path, relative to the home directory.";
          };
          capture = mkOption {
            type = types.bool;
            default = true;
            description = "Expose this file to the settings capture command. Disable for files containing credentials.";
          };
          content = mkOption {
            type = types.attrs;
            default = { };
            description = ''
              The content Nix declares. Written as JSON and converted to
              `format` on the way out, so one merge path serves every format.
            '';
          };
          contentFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = ''
              An already-rendered file to use instead of `content`, in
              `format`. For a target whose content another Home Manager
              module assembles, so this module does not duplicate an
              assembly that would drift on the next upgrade.
            '';
          };
          createIfMissing = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether to create the target when it does not exist. Set false
              for a file that is the harness's own state and should not be
              conjured on a machine where the harness has never run.
            '';
          };
          enforce = mkOption {
            type = types.listOf (types.either types.str (types.listOf types.str));
            default = [ ];
            description = ''
              Blocks this repository owns outright, reasserted on every
              activation rather than merged. A list is compared whole, so
              without this a harness that appends one entry makes the next Nix
              edit to that list an unresolvable conflict. A key the harness
              drops is also restored, which for an enforcement setting is
              required rather than a preference.

              An entry is either a string, naming one top-level key, or a list,
              naming a path into the file. `[ "extensions" "autovisualiser" ]`
              reaches one extension and leaves its siblings to the normal merge.

              A string is NEVER split on dots. amp's settings use VS Code-style
              keys, so `"amp.permissions"` is one key whose name contains dots,
              and a dotted-string syntax would silently address the wrong thing.

              Prefer the narrowest path that covers the key. Enforcing a parent
              strips every runtime field the harness writes underneath it, and
              the harness writes them back on its next run.
            '';
          };
          format = mkOption {
            type = types.enum [
              "json"
              "yaml"
              "toml"
            ];
            default = "json";
            description = "On-disk format of the target file.";
          };
          schema = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Optional path to a JSON Schema. The merged result is validated
              against it before it replaces the target.
            '';
          };
          retire = mkOption {
            type = types.listOf (types.either types.str (types.listOf types.str));
            default = [ ];
            description = ''
              Keys deleted from the target on EVERY activation. These are keys
              this repository used to declare, or that the harness writes and
              nothing reads, and which must not persist.

              A bare string is a top-level key; a list is a path, so
              `[ "extensions" "playwright" ]` reaches a nested entry. Same
              convention as `enforce`.

              It applies on every activation, not only on adoption, because a
              key that was never declared is absent from the recorded base, and
              the three-way merge preserves a base-absent key by design. Without
              this, such a key is immortal: the harness rewrites it and no code
              path removes it. A target whose schema sets
              `additionalProperties: false` then fails validation as well.
            '';
          };
        };
      }
    );
    default = { };
    description = ''
      Configuration files that both Nix and an application write. Each is
      installed as a real writable file and reconciled at activation by a
      three-way merge against a recorded base. Declaring a path here and in
      `home.file` or `xdg.configFile` is an error.
    '';
  };
}
