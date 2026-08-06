_final: prev: {
  # obsidian 1.13.4 does not unpack on Darwin. The upstream expression takes the
  # default `sourceRoot`, which resolves to `Obsidian.app`, but the 1.13.4 dmg
  # nests the bundle one level down under `Obsidian <version>-universal/`. The
  # unpack itself succeeds and the next line fails:
  #
  #   source root is Obsidian.app
  #   chmod: cannot access 'Obsidian.app': No such file or directory
  #
  # That takes the whole system closure with it, because home-manager-applications
  # depends on it, so a broken app package fails the switch rather than one app.
  # 1.12.7 unpacked fine, so this arrived with a nixpkgs bump, not with a change here.
  #
  # Point `sourceRoot` at the real path rather than pinning back to 1.12.7: the
  # packaging is wrong, the app is not, and a version pin would have to be unpinned
  # by hand once upstream fixes it. This override becomes a no-op the moment the
  # dmg layout matches the default again, and the build fails loudly if it does not.
  #
  # Guarded to Darwin: the dmg path only exists there, and touching obsidian on
  # Linux perturbs its closure for no reason.
  obsidian =
    if prev.stdenv.hostPlatform.isDarwin then
      prev.obsidian.overrideAttrs (old: {
        sourceRoot = "Obsidian ${old.version}-universal/Obsidian.app";
      })
    else
      prev.obsidian;
}
