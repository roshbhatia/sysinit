{
  ...
}:

{
  imports = [
    ./packages/nixpkgs/nixpkgs.nix
    ./packages/cargo/cargo.nix
    ./packages/gh/gh.nix
    ./packages/go/go.nix
    ./packages/krew/krew.nix
    ./packages/node/npm.nix
    ./packages/node/yarn.nix
    ./packages/python/pipx.nix
    ./packages/python/uvx.nix
  
    ./configurations/aider/aider.nix
    ./configurations/atuin/atuin.nix
    ./configurations/bat/bat.nix
    ./configurations/borders/borders.nix
    ./configurations/colima/colima.nix
    ./configurations/direnv/direnv.nix
    ./configurations/git/git.nix
    ./configurations/hammerspoon/hammerspoon.nix
    ./configurations/k9s/k9s.nix
    ./configurations/macchina/macchina.nix
    ./configurations/mcp/mcp.nix
    ./configurations/neovim/neovim.nix
    ./configurations/omp/omp.nix
    ./configurations/wezterm/wezterm.nix
    ./configurations/zsh/zsh.nix
  ];
}

