# codex-acp 0.9.4 vendor path fix:
# codex-core's js_repl/mod.rs does include_str!("../../../../node-version.txt")
# but in the Cargo vendor tree the file sits one level higher, so the path needs
# five `..` segments instead of four. Patch after cargoSetupPostUnpackHook runs
# (which populates $cargoDepsCopy with a writable copy of the vendor dir).
_:

_final: prev: {
  codex-acp = prev.codex-acp.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      find "$cargoDepsCopy" -path "*/js_repl/mod.rs" -exec \
        sed -i 's|include_str!("../../../../node-version.txt")|include_str!("../../../../../node-version.txt")|g' {} +
    '';
  });
}
