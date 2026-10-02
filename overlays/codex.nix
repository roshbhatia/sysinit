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
      version = "0.159.2";
      src = final.fetchFromGitHub {
        owner = "openai";
        repo = "codex";
        tag = "rust-v0.159.2";
        hash = "sha256-fYzQEit5MxsEZw/UaISMbEIsy5iaAcqb7ElEOq9eVgs=";
      };
      cargoHash = "sha256-U20V8MkGJZd+qTOQETzqB25QJPYxJGV89LiR1kToW7A=";
      cargoDeps = rustPlatform.fetchCargoVendor {
        inherit (new) src;
        name = "codex-${new.version}";
        sourceRoot = "${new.src.name}/codex-rs";
        hash = new.cargoHash;
      };
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
