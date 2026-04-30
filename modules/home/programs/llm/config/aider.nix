{ pkgs, lib, ... }:
let
  # kvazaar CTest suite fails on aarch64-darwin in nixpkgs-unstable
  ffmpegNoKvazaar = pkgs.ffmpeg-full.override { withKvazaar = false; };
  aiderBase = pkgs.aider-chat.override { ffmpeg = ffmpegNoKvazaar; };
in
{
  programs.aider-chat = {
    enable = true;
    # Upstream nixpkgs 0.86.1 package has failing tests; skip them
    package = aiderBase.overridePythonAttrs (_: { doCheck = false; });
    settings = {
      dark-mode = true;
      cache-prompts = true;
      dirty-commits = false;
      show-model-warnings = false;
      auto-accept-architect = false;
    };
  };
}
