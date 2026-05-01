{ config, pkgs, ... }:

let
  interfaceFont = config.sysinit.theme.font.monospace;

  vimrcSupport = {
    "main.js" = pkgs.fetchurl {
      url = "https://github.com/esm7/obsidian-vimrc-support/releases/download/0.10.2/main.js";
      hash = "sha256-aGNzThnu8lBeBUJQyoIbxTL21iceb1AXKx6KBHNObOI=";
    };
    "manifest.json" = pkgs.fetchurl {
      url = "https://github.com/esm7/obsidian-vimrc-support/releases/download/0.10.2/manifest.json";
      hash = "sha256-st5aS+ORuI69konjgVYtFJGlh5ef0Iu9pqf/Ub4n0FY=";
    };
  };
in
{
  programs.obsidian = {
    enable = true;

    vaults = {
      MainVault = {
        enable = true;
        target = "orgfiles";

        settings = {
          app = {
            "vim-mode" = true;
          };

          appearance = {
            baseFontSize = 11;
            interfaceFontFamily = interfaceFont;
            monospaceFontFamily = "IBM Plex Mono";
            textFontFamily = "Bookerly";
            enabledCssSnippets = [ "Stylix Config" ];
          };

          extraFiles = {
            ".obsidian/community-plugins.json" = {
              text = builtins.toJSON [
                "obsidian-git"
                "obsidian-importer"
                "table-editor-obsidian"
                "obsidian-vimrc-support"
              ];
            };
            ".obsidian.vimrc" = {
              text = ''
                " Options
                set autoindent
                set hlsearch
                set ignorecase
                set incsearch
                set linebreak
                set number
                set relativenumber
                set smartcase
                set smartindent

                " Leader key matches neovim
                let mapleader = " "

                " J/K scroll 5 lines (approximates <C-d>/<C-u> feel)
                noremap J 5j
                noremap K 5k

                " H/L to line start/end
                noremap H ^
                noremap L $

                " Clear search highlight on Escape
                nmap <Esc> :nohl

                " Y yanks to end of line (matches neovim default)
                nmap Y y$

                " File navigation — matches <leader>ff / <leader>fg in neovim
                exmap quickOpen obcommand switcher:open
                nmap <leader>ff :quickOpen

                exmap globalSearch obcommand global-search:open
                nmap <leader>fg :globalSearch

                " History navigation — matches <C-o> / <C-i> in neovim
                exmap goBack obcommand app:go-back
                nmap <C-o> :goBack

                exmap goForward obcommand app:go-forward
                nmap <C-i> :goForward

                " Command palette — matches <leader><leader> (command mode) in neovim
                exmap commandPalette obcommand command-palette:open
                nmap <leader><leader> :commandPalette

                " Backlinks pane — matches <leader>e* explorer family in neovim
                exmap openBacklinks obcommand backlink:open
                nmap <leader>eb :openBacklinks

                " Git — matches <leader>gg in neovim
                exmap gitStatus obcommand obsidian-git:open-source-control-view
                nmap <leader>gg :gitStatus
              '';
            };

            ".obsidian/plugins/obsidian-vimrc-support/main.js" = {
              source = vimrcSupport."main.js";
            };
            ".obsidian/plugins/obsidian-vimrc-support/manifest.json" = {
              source = vimrcSupport."manifest.json";
            };
          };
        };
      };
    };
  };
}
