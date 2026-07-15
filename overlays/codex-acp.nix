# codex-acp 0.12.0 vendor path fix:
# codex-core's js_repl/mod.rs has include_str!("../../../../../node-version.txt")
# but in the Cargo vendor tree the file sits one level closer, so the path needs
# four `..` segments instead of five.
_:

final: prev: {
  codex-acp = prev.codex-acp.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      find "$cargoDepsCopy" -path "*/js_repl/mod.rs" -exec \
        sed -i 's|include_str!("../../../../../node-version.txt")|include_str!("../../../../node-version.txt")|g' {} +
    '';
    # cctools ld crashes (SIGTRAP, exit 133) on Darwin 25.x — use ld64.lld instead.
    # Guard to Darwin: ld64.lld is Mach-O only; gcc on Linux rejects the flag.
    nativeBuildInputs =
      (old.nativeBuildInputs or [ ])
      ++ (if prev.stdenv.isDarwin then [ final.llvmPackages_latest.lld ] else [ ]);
    RUSTFLAGS =
      if prev.stdenv.isDarwin then
        "${old.RUSTFLAGS or ""} -C link-arg=-fuse-ld=${final.llvmPackages_latest.lld}/bin/ld64.lld"
      else
        (old.RUSTFLAGS or "");
  });
}
