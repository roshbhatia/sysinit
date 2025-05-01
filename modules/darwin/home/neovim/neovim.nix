{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;
    
    extraPackages = with pkgs; [
      # Language servers
      nodePackages.bash-language-server            # bashls
      dagger                                       # dagger
      nodePackages.docker-compose-language-service # docker_compose_language_service
      nodePackages.dockerfile-language-server-nodejs # dockerls
      golangci-lint-langserver                    # golangci_lint_ls
      gopls                                       # gopls
      helm-ls                                     # helm_ls
      html-lsp                                    # html
      nodePackages.jq-lsp                         # jqls
      marksman                                    # marksman
      spectral                                    # spectral
      terraform-ls                                # terraformls
      tflint                                      # tflint
      nodePackages.typescript-language-server     # ts_ls
      
      # Linters and tools
      nodePackages.eslint                         # JavaScript/TypeScript linting
      golangci-lint                               # Go linting
      shellcheck                                  # Shell script linting
      nodePackages.jsonlint                       # JSON linting
      nodePackages.markdownlint-cli               # Markdown linting
      
      # Additional helpful tools
      nodePackages.prettier                       # Code formatting
      nixpkgs-fmt                                 # Nix formatting
      python3Packages.black                       # Python formatting
      python3Packages.pylint                      # Python linting
    ];
  };

  # Using mkOutOfStoreSymlink for Neovim config
  xdg.configFile."nvim/init.lua" = {
    source = config.lib.file.mkOutOfStoreSymlink ./init.lua;
  };

  xdg.configFile."nvim/lua" = {
    source = config.lib.file.mkOutOfStoreSymlink ./lua;
    recursive = true;
  };

  # Keep only the VSCode key repeat settings
  home.activation.vscodeKeySettings = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      if [ "$(/usr/bin/defaults read com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled 2>/dev/null)" != "0" ]; then
        echo "Configuring VSCode key repeat settings"
        /usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false
      fi
    '';
  };
}
