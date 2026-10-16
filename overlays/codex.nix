final: prev:
let
  toolchain = final.rust-bin.stable."1.95.0".minimal;
  rustPlatform = final.makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  };
in
{
  codex = (prev.codex.override { inherit rustPlatform; }).overrideAttrs (
    new: old: {
      version = "0.163.0";
      buildCommit = "83086188ae0614bd882818ff1aa23f3194962012";
      src = final.fetchFromGitHub {
        owner = "openai";
        repo = "codex";
        tag = "rust-v0.163.0";
        hash = "sha256-Fa9dfiGJy+uqSF4A0EM6AQQhhjQdu+jfhKzqXid9PNA=";
      };
      cargoHash = "sha256-TG1fDHQCRDDbk+G0NS/9NTouJupq0Zisi4LIJY4SgYw=";
      cargoDeps =
        (rustPlatform.fetchCargoVendor {
          inherit (new) src;
          name = "codex-${new.version}";
          sourceRoot = "${new.src.name}/codex-rs";
          hash = new.cargoHash;
        }).overrideAttrs
          (oldDeps: {
            buildCommand = oldDeps.buildCommand + ''
              chmod +w "$out/source-registry-0/opusic-sys-0.7.5/Cargo.toml"
              substituteInPlace "$out/source-registry-0/opusic-sys-0.7.5/Cargo.toml" \
                --replace-fail 'default = ["bundled"]' 'default = []'
            '';
          });
      patches = (old.patches or [ ]) ++ [
        ./codex-sanitize-terminal-output.patch
        ./codex-mcp-capabilities.patch
      ];
      doCheck = true;
      cargoTestFlags = [
        "--package"
        "codex-ansi-escape"
      ];
    }
  );
}
