# codex-acp 0.12.0 vendor path fix:
# codex-core's js_repl/mod.rs has include_str!("../../../../../node-version.txt")
# but in the Cargo vendor tree the file sits one level closer, so the path needs
# four `..` segments instead of five.
_:

_final: prev: {
  codex-acp = prev.codex-acp.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      find "$cargoDepsCopy" -path "*/js_repl/mod.rs" -exec \
        sed -i 's|include_str!("../../../../../node-version.txt")|include_str!("../../../../node-version.txt")|g' {} +
    '';
  });
}
