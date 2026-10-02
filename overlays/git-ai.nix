final: _prev:
let
  toolchain = final.rust-bin.stable."1.95.0".minimal;
  rustPlatform = final.makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  };
in
{
  git-ai = rustPlatform.buildRustPackage {
    pname = "git-ai";
    version = "1.7.5";
    src = final.fetchFromGitHub {
      owner = "git-ai-project";
      repo = "git-ai";
      rev = "f67fe0d732dfebf6bc229ad7c784e3a8a2d42a66";
      hash = "sha256-e4hJMjWoHRRycYekbcM5hLIyNnz7xSeIO2Hx5xz4jX0=";
    };
    cargoHash = "sha256-/a2YpqhN5hbrFJTcehEPkFH9Jsinqf4sYTRiN+OTqp4=";
    patches = [ ./git-ai-codex-pre-edit.patch ];
    nativeBuildInputs = [
      final.pkg-config
      final.git
    ];
    buildInputs = final.lib.optionals final.stdenv.hostPlatform.isLinux [ final.openssl ];
    env = final.lib.optionalAttrs final.stdenv.hostPlatform.isLinux {
      OPENSSL_NO_VENDOR = "1";
    };
    doCheck = true;
    cargoTestFlags = [
      "--lib"
      "commands::checkpoint_agent::presets::codex::tests"
    ];
    meta = with final.lib; {
      description = "Git extension for line-level AI-code authorship attribution, stored in git notes";
      homepage = "https://github.com/git-ai-project/git-ai";
      license = licenses.asl20;
      mainProgram = "git-ai";
    };
  };
}
