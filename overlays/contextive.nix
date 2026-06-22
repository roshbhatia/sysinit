_:

final: _prev:
let
  contextiveVersion = "1.17.8";
  # Hashes are for the raw zip file (used with fetchurl, not fetchzip)
  contextiveSources = {
    "x86_64-linux" = {
      platform = "linux-x64";
      sha256 = "sha256-bnmEFxtcCi/D/lNyjm8OHGoRj6HFWKkD7CWD0GG//4s=";
    };
    "aarch64-linux" = {
      platform = "linux-arm64";
      sha256 = "sha256-NqAaBKVql9QFgcUnzUdFxJb9/jASZn9voc4tJ1fWt4w=";
    };
    "x86_64-darwin" = {
      platform = "osx-x64";
      sha256 = "sha256-ZDqPWkE849oMK0r6XY4miBNo0xJ0Vfb57GqNkSTNBX8=";
    };
    "aarch64-darwin" = {
      platform = "osx-arm64";
      sha256 = "sha256-AGqk0NeysNV7ZmuTxWZZYNISZkCgt/Qei8NkcLTUSGA=";
    };
  };
  contextiveSource =
    contextiveSources.${final.stdenv.hostPlatform.system}
      or (throw "contextive: Unsupported platform ${final.stdenv.hostPlatform.system}");
in
{
  contextive = final.stdenv.mkDerivation {
    pname = "contextive";
    version = contextiveVersion;

    src = final.fetchurl {
      url = "https://github.com/dev-cycles/contextive/releases/download/v${contextiveVersion}/Contextive.LanguageServer-${contextiveSource.platform}-${contextiveVersion}.zip";
      inherit (contextiveSource) sha256;
    };

    nativeBuildInputs = [
      final.unzip
    ]
    ++ final.lib.optionals final.stdenv.isLinux [ final.autoPatchelfHook ];

    # .NET single-file bundle: managed assemblies are appended to the apphost.
    # Stripping rewrites the Mach-O and truncates that trailer, which makes the
    # runtime fail with "possible file corruption" on launch.
    dontStrip = true;

    buildInputs = final.lib.optionals final.stdenv.isLinux [
      final.stdenv.cc.cc.lib
      final.icu
      final.openssl
      final.zlib
    ];

    unpackPhase = ''
      runHook preUnpack
      unzip $src -d .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/lib
      cp Contextive.LanguageServer $out/lib/
      chmod +x $out/lib/Contextive.LanguageServer
      ln -s $out/lib/Contextive.LanguageServer $out/bin/Contextive.LanguageServer
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Language server for managing domain-driven design ubiquitous language definitions";
      homepage = "https://github.com/dev-cycles/contextive";
      license = licenses.mit;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      mainProgram = "Contextive.LanguageServer";
    };
  };
}
