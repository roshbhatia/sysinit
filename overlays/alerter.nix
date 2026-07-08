_:

final: _prev: {
  # alerter — terminal-notifier's actionable cousin: shows a macOS notification
  # with Accept/Deny buttons and prints the chosen action to stdout, so a hook
  # can relay the human's decision back into the agent pane.
  #
  # Not in nixpkgs (design.md D2). The upstream release ships a single prebuilt
  # arm64 Mach-O binary in a zip — installed verbatim, hash-pinned so a re-cut
  # release fails the build loudly rather than shipping unverified bytes. macOS
  # only (NotificationCenter); the derivation carries `platforms.darwin` so it is
  # never pulled into a linux closure.
  alerter = final.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "alerter";
    version = "26.5";

    src = final.fetchurl {
      url = "https://github.com/vjeantet/alerter/releases/download/v${finalAttrs.version}/alerter-${finalAttrs.version}.zip";
      hash = "sha256-EfY83cm7P4VU7Zt2JjKhIM+nvuBePAnWVzSCPgnSTxA=";
    };

    nativeBuildInputs = [ final.unzip ];

    # The zip holds a bare `alerter` binary (no top-level directory), so unpack
    # into a scratch dir rather than letting unzip splatter cwd.
    unpackPhase = ''
      runHook preUnpack
      mkdir -p source
      unzip -q "$src" -d source
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 source/alerter "$out/bin/alerter"
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "terminal-notifier fork that returns the user's action choice";
      homepage = "https://github.com/vjeantet/alerter";
      license = licenses.mit;
      mainProgram = "alerter";
      platforms = platforms.darwin;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    };
  });
}
