_:
{
  # Install the forked rosh-spec-driven OpenSpec schema to the XDG data dir so
  # `openspec` resolves it in every project as `Source: user`, not only inside
  # sysinit. openspec resolves schemas from `$XDG_DATA_HOME/openspec/schemas/`
  # (getGlobalDataDir, falling back to ~/.local/share/openspec). The source is
  # the in-repo schema dir, so a schema edit in the repo is the only authoring
  # site; the install is a rebuild-gated snapshot like every other nix file.
  xdg.dataFile."openspec/schemas/rosh-spec-driven".source =
    ../../../../openspec/schemas/rosh-spec-driven;
}
