{ lib, ... }:
let
  # In-repo schema dir; the repo is the only authoring site and the install is
  # a rebuild-gated snapshot like every other nix-managed file.
  schemaSrc = ../../../../openspec/schemas/rosh-spec-driven;

  # Declare every schema file individually so home-manager materializes
  # `openspec/schemas/rosh-spec-driven/` as a REAL directory and symlinks only
  # the leaf files. A whole-dir source (with or without recursive = true) leaves
  # `rosh-spec-driven` a symlink, and openspec's listSchemas
  # (readdirSync withFileTypes, used by `openspec new change` to validate the
  # default schema and by `schema which --all`) skips entries where
  # entry.isDirectory() is false, so a symlinked schema is invisible even though
  # `schema which <name>` (existsSync, follows symlinks) finds it. Real
  # intermediate dirs make the entry a directory, so listSchemas enumerates it.
  relPath = f: lib.removePrefix (toString schemaSrc + "/") (toString f);
  schemaFiles = lib.filesystem.listFilesRecursive schemaSrc;
in
{
  xdg.dataFile = lib.listToAttrs (
    map (
      f: lib.nameValuePair "openspec/schemas/rosh-spec-driven/${relPath f}" { source = f; }
    ) schemaFiles
  );
}
