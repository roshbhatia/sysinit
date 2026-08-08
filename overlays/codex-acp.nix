final: prev: {
  codex-acp = prev.codex-acp.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      find "$cargoDepsCopy" -path "*/js_repl/mod.rs" -exec \
        sed -i 's|include_str!("../../../../../node-version.txt")|include_str!("../../../../node-version.txt")|g' {} +
    '';
    nativeBuildInputs =
      (old.nativeBuildInputs or [ ])
      ++ (if prev.stdenv.hostPlatform.isDarwin then [ final.llvmPackages_latest.lld ] else [ ]);
    RUSTFLAGS =
      if prev.stdenv.hostPlatform.isDarwin then
        "${old.RUSTFLAGS or ""} -C link-arg=-fuse-ld=${final.llvmPackages_latest.lld}/bin/ld64.lld"
      else
        (old.RUSTFLAGS or "");
  });
}
