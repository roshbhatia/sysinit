_final: prev: {
  obsidian =
    if prev.stdenv.hostPlatform.isDarwin then
      prev.obsidian.overrideAttrs (old: {
        sourceRoot = "Obsidian ${old.version}-universal/Obsidian.app";
      })
    else
      prev.obsidian;
}
