final: _prev:
let
  sources = final.nvfetcherSources;
  inherit (sources.atomic-coding-agent) version;

  platformInfo = {
    "aarch64-darwin" = sources.atomic-coding-agent.src;
    "x86_64-darwin" = sources.atomic-coding-agent-x86_64-darwin.src;
    "aarch64-linux" = sources.atomic-coding-agent-aarch64-linux.src;
    "x86_64-linux" = sources.atomic-coding-agent-x86_64-linux.src;
  };

  src =
    platformInfo.${final.stdenv.hostPlatform.system}
      or (throw "atomic-coding-agent: Unsupported platform ${final.stdenv.hostPlatform.system}");
in
{
  atomic-coding-agent = final.stdenv.mkDerivation {
    pname = "atomic-coding-agent";
    inherit version src;

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp -r atomic $out/
      ln -s $out/atomic/atomic $out/bin/atomic
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Coding agent runtime with stages, checks, and approval gates";
      homepage = "https://github.com/bastani-inc/atomic";
      # `package.json` says MIT; GitHub reports NOASSERTION because the tarball
      # ships no LICENSE file. Taking the declaration in the package metadata.
      license = licenses.mit;
      mainProgram = "atomic";
    };
  };
}
