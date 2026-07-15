_:

final: prev: {
  goose-cli = prev.goose-cli.overrideAttrs (old: {
    doCheck = false;
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
