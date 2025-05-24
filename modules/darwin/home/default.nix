{
  ...
}:

{
  imports = [
    ./core/packages.nix

    ./aider/aider.nix
    ./atuin/atuin.nix
    ./bat/bat.nix
    ./borders/borders.nix
    ./colima/colima.nix
    ./git/git.nix
    ./k9s/k9s.nix
    ./macchina/macchina.nix
    ./mcp/mcp.nix
    ./neovim/neovim.nix
    ./omp/omp.nix
    ./wezterm/wezterm.nix
    ./zsh/zsh.nix

    ./cargo/cargo.nix
    ./gh/gh.nix
    ./go/go.nix
    ./krew/krew.nix
    ./node/npm.nix
    ./node/yarn.nix
    ./python/pipx.nix
    ./python/uvx.nix
  ];
}
