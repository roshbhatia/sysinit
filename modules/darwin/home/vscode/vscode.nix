{config, lib, pkgs, ...}:

let
  extensions = [
    "ukoloff.win-ca" # Fixes the issue with self-signed certificates
    "aaron-bond.better-comments"
    "asvetliakov.vscode-neovim"
    "bbenoist.nix"
    "bdavs.expect"
    "bierner.markdown-mermaid"
    "carlthome.git-line-blame"
    "catppuccin.catppuccin-vsc-icons"
    "davidanson.vscode-markdownlint"
    "davidbwaters.macos-modern-theme"
    "drcika.apc-extension"
    "emily-curry.base16-tomorrow-dark-vscode"
    "esbenp.prettier-vscode"
    "evan-buss.font-switcher"
    "github.copilot"
    "github.copilot-chat"
    "github.vscode-pull-request-github"
    "github.vscode-github-actions"
    "golang.go"
    "gziz.snip-notes"
    "hashicorp.terraform"
    "illixion.vscode-vibrancy-continued"
    "jerrygoyal.shortcut-menu-bar"
    "jfacoustic.line-num-toggle"
    "kdl-org.kdl"
    "matthewpi.caddyfile-support"
    "meezilla.json"
    "mindaro-dev.file-downloader"
    "ms-vscode-remote.remote-ssh"
    "ms-vscode-remote.remote-ssh-edit"
    "ms-vscode.remote-explorer"
    "ms-vscode.vscode-typescript-next"
    "ms-vscode.vscode-websearchforcopilot"
    "peterj.proto"
    "redhat.vscode-yaml"
    "romantomjak.go-template"
    "sibiraj-s.vscode-scss-formatter"
    "tamasfe.even-better-toml"
    "task.vscode-task"
    "timonwong.shellcheck"
    "usernamehw.errorlens"
    "wholroyd.jinja"
    "yinfei.luahelper"
    "zaidalsaheb.search-preview"
    "ziglang.vscode-zig"
  ];
in
{
  xdg.configFile = {
    "vscode/keybindings.json".source = ./config/keybindings.json;
    "vscode/settings.json".source = ./config/settings.json;
  };

home.activation.installExtensions = {
    after = [ "fixVariables" ];
    before = [];
    data = ''
      echo "Installing VSCode Insiders extensions..."
      # export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
      # export NODE_OPTIONS="--use-system-ca"
      
      # extensions=(${builtins.concatStringsSep " " extensions})
      
      # for ext in "''${extensions[@]}"; do
      #  if ! /opt/homebrew/bin/code-insiders --install-extension "$ext" --force; then
      #    printf "❌ Failed to install extension: %s\n" "$ext"
      #    exit 1
      #  else
      #    printf "✅ Successfully installed: %s\n" "$ext"
      #  fi
      # done
      
      echo "Copying VS Code configuration files..."
      install -v $HOME/.config/vscode/keybindings.json "$HOME/Library/Application Support/Code - Insiders/User/keybindings.json"
      install -v $HOME/.config/vscode/settings.json "$HOME/Library/Application Support/Code - Insiders/User/settings.json"
    '';
  };
}