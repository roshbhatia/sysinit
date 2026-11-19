final: _prev:
let
  sources = final.nvfetcherSources;
  inherit (sources.agent-desktop) version;

  platformInfo = {
    "aarch64-darwin" = {
      inherit (sources.agent-desktop) src;
      helper = "agent-desktop-macos-helper";
    };
    "aarch64-linux" = {
      inherit (sources.agent-desktop-aarch64-linux) src;
      helper = "agent-desktop-linux-clipboard-owner";
    };
    "x86_64-linux" = {
      inherit (sources.agent-desktop-x86_64-linux) src;
      helper = "agent-desktop-linux-clipboard-owner";
    };
  };

  info = platformInfo.${final.stdenv.hostPlatform.system};
in
{
  agent-desktop = final.stdenv.mkDerivation {
    pname = "agent-desktop";
    inherit version;

    inherit (info) src;

    sourceRoot = ".";

    nativeBuildInputs = final.lib.optionals final.stdenv.hostPlatform.isLinux [ final.autoPatchelfHook ];
    buildInputs = final.lib.optionals final.stdenv.hostPlatform.isLinux [ final.stdenv.cc.cc.lib ];

    # The CLI looks for its platform helper in its own directory.
    installPhase = ''
      runHook preInstall
      install -Dm755 agent-desktop $out/bin/agent-desktop
      install -Dm755 ${info.helper} $out/bin/${info.helper}
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Computer use for AI agents through the OS accessibility tree";
      homepage = "https://github.com/vercel-labs/agent-desktop";
      license = licenses.asl20;
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
      platforms = builtins.attrNames platformInfo;
      mainProgram = "agent-desktop";
    };
  };
}
