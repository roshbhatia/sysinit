_:

final: prev: {
  ast-grep = prev.ast-grep.overrideAttrs (oldAttrs: {
    # Skip tests on Darwin as they fail with "Illegal byte sequence (os error 92)"
    doCheck = !prev.stdenv.hostPlatform.isDarwin;
    # cctools ld crashes (SIGTRAP, exit 133) on Darwin 25.x — use ld64.lld instead.
    # Guard to Darwin: ld64.lld is Mach-O only; gcc on Linux rejects the flag.
    nativeBuildInputs =
      (oldAttrs.nativeBuildInputs or [ ])
      ++ (if prev.stdenv.isDarwin then [ final.llvmPackages_latest.lld ] else [ ]);
    RUSTFLAGS =
      if prev.stdenv.isDarwin then
        "${oldAttrs.RUSTFLAGS or ""} -C link-arg=-fuse-ld=${final.llvmPackages_latest.lld}/bin/ld64.lld"
      else
        (oldAttrs.RUSTFLAGS or "");
  });
}
