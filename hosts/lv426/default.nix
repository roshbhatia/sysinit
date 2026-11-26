{ personal }:

{
  system = "aarch64-darwin";
  platform = "darwin";
  profile = "workstation";
  inherit (personal) username;
  values = {
    inherit (personal) git;
    packages = [
      "beads"
      "black"
      "claude-powerline"
      "fluxcd"
      "markdownlint-cli"
      "mcp-proxy"
      "mermaid-cli"
      "spec-kit"
      "stack"
      "temporal-cli"
    ];
    environment.PUPPETEER_EXECUTABLE_PATH = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
    wezterm.remoteMux = true;
    theme.base16Scheme = personal.rosePine;
    darwin.homebrew.additionalPackages.casks = [
      "google-chrome"
      "vesktop"
      "vlc"
    ];
    darwin.openssh = {
      enable = true;
      inherit (personal) authorizedKeys;
    };
  };
}
