final: _prev:
let
  sources = final.nvfetcherSources;
  inherit (sources.fx) version;

  # The tarball is flat and its name carries no platform, so only the source
  # differs per system. The linux binaries are statically linked, so neither
  # autoPatchelfHook nor a runtime dependency is needed.
  srcFor = {
    "aarch64-darwin" = sources.fx.src;
    "x86_64-darwin" = sources.fx-x86_64-darwin.src;
    "aarch64-linux" = sources.fx-aarch64-linux.src;
    "x86_64-linux" = sources.fx-x86_64-linux.src;
  };
in
{
  fx = final.stdenv.mkDerivation {
    pname = "fx";
    inherit version;

    src = srcFor.${final.stdenv.hostPlatform.system};

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      install -Dm755 fx $out/bin/fx
      install -Dm644 LICENSE $out/share/licenses/fx/LICENSE
      install -Dm644 THIRD_PARTY_NOTICES.md $out/share/licenses/fx/THIRD_PARTY_NOTICES.md
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Unix-like coding agent";
      homepage = "https://github.com/vercel-labs/fx";
      license = licenses.asl20;
      mainProgram = "fx";
      platforms = builtins.attrNames srcFor;
    };
  };
}
