_:

final: _prev:
let
  sources = final.nvfetcherSources;
  inherit (sources.pi-coding-agent) version;

  platformInfo = {
    "aarch64-darwin" = sources.pi-coding-agent.src;
    "x86_64-darwin" = sources.pi-coding-agent-x86_64-darwin.src;
    "aarch64-linux" = sources.pi-coding-agent-aarch64-linux.src;
    "x86_64-linux" = sources.pi-coding-agent-x86_64-linux.src;
  };

  src =
    platformInfo.${final.stdenv.hostPlatform.system}
      or (throw "pi-coding-agent: Unsupported platform ${final.stdenv.hostPlatform.system}");
in
{
  pi-coding-agent = final.stdenv.mkDerivation {
    pname = "pi-coding-agent";
    inherit version src;

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp -r pi $out/
      ln -s $out/pi/pi $out/bin/pi
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Coding agent CLI with read, bash, edit, write tools and session management";
      homepage = "https://github.com/badlogic/pi-mono";
      license = licenses.mit;
      mainProgram = "pi";
    };
  };
}
