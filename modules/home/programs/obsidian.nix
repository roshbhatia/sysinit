{ config, ... }:

let
  interfaceFont = config.sysinit.theme.font.monospace;
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

                " Scroll with J/K like Ctrl-D/U
                noremap J 5j
                noremap K 5k

                " H/L to line start/end
                noremap H ^
                noremap L $

                " Clear search highlight on Escape (matches neovim)
                nmap <Esc> :nohl

                " Yank to end of line (matches Y in neovim)
                nmap Y y$
              '';
            };
          };
        };
      };
    };
  };
}
