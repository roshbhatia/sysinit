_: {
  # Install the forked rosh-spec-driven OpenSpec schema to the XDG data dir so
  # `openspec` resolves it in every project as `Source: user`, not only inside
  # sysinit. openspec resolves schemas from `$XDG_DATA_HOME/openspec/schemas/`
  # (getGlobalDataDir, falling back to ~/.local/share/openspec). The source is
  # the in-repo schema dir, so a schema edit in the repo is the only authoring
  # site; the install is a rebuild-gated snapshot like every other nix file.
  #
  # recursive = true is required: openspec's listSchemas (used by
  # `openspec new change` to validate the default schema, and by
  # `schema which --all`) enumerates the user dir with readdirSync withFileTypes
  # and skips entries where entry.isDirectory() is false. A plain xdg.dataFile
  # symlinks the whole dir, and a Dirent for a symlink reports isDirectory()
  # false, so the schema is invisible to listSchemas even though `schema which`
  # (existsSync, follows symlinks) finds it. recursive = true materializes a
  # real directory of per-file symlinks, so the entry is a real dir.
  xdg.dataFile."openspec/schemas/rosh-spec-driven" = {
    source = ../../../../openspec/schemas/rosh-spec-driven;
    recursive = true;
  };
}
