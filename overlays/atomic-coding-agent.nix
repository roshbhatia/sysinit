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

  legacyPiAliases = [
    "PI_CODING_AGENT_DIR"
    "PI_CODING_AGENT_SESSION_DIR"
    "PI_PACKAGE_DIR"
    "PI_OFFLINE"
    "PI_SKIP_VERSION_CHECK"
    "PI_TELEMETRY"
    "PI_REDUCED_MOTION"
    "PI_SESSION_ID"
    "PI_SESSION_FILE"
    "PI_PROVIDER"
    "PI_MODEL"
    "PI_REASONING_LEVEL"
  ];
in
{
  atomic-coding-agent = final.stdenv.mkDerivation {
    pname = "atomic-coding-agent";
    inherit version src;

    sourceRoot = ".";

    nativeBuildInputs = [ final.makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp -r atomic $out/
      makeWrapper $out/atomic/atomic $out/bin/atomic \
        ${final.lib.concatMapStringsSep " " (name: "--unset ${name}") legacyPiAliases} \
        --run 'export ATOMIC_CODING_AGENT_DIR="''${ATOMIC_CODING_AGENT_DIR:-$HOME/.atomic/agent}"' \
        --run 'export ATOMIC_SKIP_VERSION_CHECK="''${ATOMIC_SKIP_VERSION_CHECK:-1}"'
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      got=$(PI_CODING_AGENT_DIR=/should/not/reach/atomic $out/bin/atomic --version 2>&1)
      case "$got" in
        *${version}*) ;;
        *)
          echo "atomic --version printed '$got', expected it to name ${version}" >&2
          exit 1
          ;;
      esac
      runHook postInstallCheck
    '';

    meta = with final.lib; {
      description = "Coding agent runtime with stages, checks, and approval gates";
      homepage = "https://github.com/bastani-inc/atomic";
      license = licenses.mit;
      mainProgram = "atomic";
    };
  };
}
