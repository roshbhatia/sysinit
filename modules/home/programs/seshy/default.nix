_: {
  # Nix-manage seshy's user config (previously hand-written) so Roshan-specific
  # session setup survives a fresh machine. Kept separate from the seshy project
  # itself. The postCreate hook runs `openspec init`, which defaults to the
  # machine-wide spec-driven schema, so every new session inherits our
  # openspec config without touching the seshy repo.
  xdg.configFile."seshy/config.yaml".source = ./config.yaml;
}
