final: prev:
let
  source = final.nvfetcherSources."github-copilot-cli-${prev.stdenv.hostPlatform.system}";
in
{
  github-copilot-cli = prev.github-copilot-cli.overrideAttrs (_: {
    inherit (source) version src;
    doInstallCheck = true;
  });
}
