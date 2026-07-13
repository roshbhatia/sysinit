_:

final: prev: {
  goose-cli = prev.goose-cli.overrideAttrs (old: {
    doCheck = false;
    # cctools ld crashes (SIGTRAP, exit 133) on Darwin 25.x — use ld64.lld instead.
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages_latest.lld ];
    RUSTFLAGS = "${old.RUSTFLAGS or ""} -C link-arg=-fuse-ld=${final.llvmPackages_latest.lld}/bin/ld64.lld";
  });
}
