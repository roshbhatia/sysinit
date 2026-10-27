final: prev:
let
  toolchain = final.rust-bin.stable."1.99.1".minimal;
  rustPlatform = final.makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  };
in
{
  codex = (prev.codex.override { inherit rustPlatform; }).overrideAttrs (
    new: old: {
      version = "0.164.0";
      buildCommit = "6aaac694803004a63c6f393d153c96d22521a6b9";
      src = final.fetchFromGitHub {
        owner = "openai";
        repo = "codex";
        tag = "rust-v0.164.0";
        hash = "sha256-iib2+qQcGewC4Ga8cA80sInDJpzdSxDJP0y1DDOouI4=";
      };
      cargoHash = "sha256-0N2mEGqEl2ZjWqlbraVCWP0eoITgwmT9uO/1w/1eJno=";
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
