{
  flake.modules.homeManager = {
    bash = ./bash.nix;
    direnv = ./direnv.nix;
    nixYourShell = ./nix-your-shell.nix;
    omp = ./omp.nix;
    vivid = ./vivid.nix;
    zoxide = ./zoxide.nix;
    zsh = ./zsh/default.nix;
  };
}
