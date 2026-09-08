final: _prev:
let
  sources = final.nvfetcherSources;
  inherit (sources.git-ai) version;

  platformInfo = {
    "aarch64-darwin" = sources.git-ai.src;
    "x86_64-darwin" = sources.git-ai-x86_64-darwin.src;
    "aarch64-linux" = sources.git-ai-aarch64-linux.src;
    "x86_64-linux" = sources.git-ai-x86_64-linux.src;
  };

  src = platformInfo.${final.stdenv.hostPlatform.system};
in
{
  # The release assets are single statically linked binaries (no PT_INTERP, no
  # PT_DYNAMIC on linux), so they install like localias and need no
  # autoPatchelfHook.
  git-ai = final.stdenv.mkDerivation {
    pname = "git-ai";
    inherit version src;

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/git-ai
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      got=$($out/bin/git-ai --version 2>&1)
      case "$got" in
        *${version}*) ;;
        *)
          echo "git-ai --version printed '$got', expected it to name ${version}" >&2
          exit 1
          ;;
      esac
      runHook postInstallCheck
    '';

    meta = with final.lib; {
      description = "Git extension for line-level AI-code authorship attribution, stored in git notes";
      homepage = "https://github.com/git-ai-project/git-ai";
      license = licenses.asl20;
      mainProgram = "git-ai";
    };
  };
}
