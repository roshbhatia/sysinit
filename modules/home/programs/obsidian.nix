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

  snippets = {
    "bullet-point-relationship-lines" = ''
      .cm-hmd-list-indent .cm-tab,
      ul ul {
        position: relative;
      }
      .cm-hmd-list-indent .cm-tab::before,
      ul ul::before {
        content: "";
        border-left: 1px solid rgba(0, 122, 255, 0.25);
        position: absolute;
      }
      .cm-hmd-list-indent .cm-tab::before {
        left: 0;
        top: -5px;
        bottom: -4px;
      }
      ul ul::before {
        left: -11px;
        top: 0;
        bottom: 0;
      }
    '';

    "smaller-scrollbar" = ''
      .CodeMirror-vscrollbar,
      .CodeMirror-hscrollbar,
      ::-webkit-scrollbar {
        width: 3px;
      }
    '';

    "enlarge-image-on-hover" = ''
      .markdown-preview-view img {
        display: block;
        margin-top: 20pt;
        margin-bottom: 20pt;
        margin-left: auto;
        margin-right: auto;
        width: 50%;
        transition: transform 0.25s ease;
      }
      .markdown-preview-view img:hover {
        transform: scale(2);
      }
    '';

    "nicer-checkboxes" = ''
      input[type="checkbox"],
      .cm-formatting-task {
        -webkit-appearance: none;
        appearance: none;
        border-radius: 50%;
        border: 1px solid var(--text-faint);
        padding: 0;
        vertical-align: middle;
      }
      .cm-s-obsidian span.cm-formatting-task {
        color: transparent;
        width: 1.25em !important;
        height: 1.25em;
        display: inline-block;
      }
      input[type="checkbox"]:focus {
        outline: 0;
      }
      input[type="checkbox"]:checked,
      .cm-formatting-task.cm-property {
        background-color: var(--text-accent-hover);
        border: 1px solid var(--text-accent-hover);
        background-position: center;
        background-size: 70%;
        background-repeat: no-repeat;
        background-image: url('data:image/svg+xml; utf8, <svg width="12px" height="10px" viewBox="0 0 12 8" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><g transform="translate(-4.000000, -6.000000)" fill="%23ffffff"><path d="M8.1043257,14.0367999 L4.52468714,10.5420499 C4.32525014,10.3497722 4.32525014,10.0368095 4.52468714,9.8424863 L5.24777413,9.1439454 C5.44721114,8.95166768 5.77142411,8.95166768 5.97086112,9.1439454 L8.46638057,11.5903727 L14.0291389,6.1442083 C14.2285759,5.95193057 14.5527889,5.95193057 14.7522259,6.1442083 L15.4753129,6.84377194 C15.6747499,7.03604967 15.6747499,7.35003511 15.4753129,7.54129009 L8.82741268,14.0367999 C8.62797568,14.2290777 8.3037627,14.2290777 8.1043257,14.0367999"></path></g></g></svg>');
      }
    '';

    "bigger-link-popup-preview" = ''
      .popover.hover-popover {
        transform: scale(0.8);
        max-height: 800px;
        min-height: 100px;
        width: 500px;
      }
      .popover.hover-popover .markdown-embed {
        height: 800px;
      }
    '';

    "image-cards" = ''
      img {
        border-radius: 4px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.12), 0 1px 2px rgba(0, 0, 0, 0.24);
        background-color: var(--background-secondary);
      }
    '';

    # Readable content width and line spacing for prose comfort
    "readable-layout" = ''
      .markdown-source-view.mod-cm6 .cm-contentContainer,
      .markdown-reading-view .markdown-preview-section {
        max-width: 720px;
        margin: 0 auto;
        line-height: 1.7;
      }
      .markdown-reading-view h1,
      .markdown-reading-view h2,
      .markdown-reading-view h3 {
        letter-spacing: -0.02em;
      }
    '';
  };

  enabledSnippets = [
    "Stylix Config"
    "bullet-point-relationship-lines"
    "smaller-scrollbar"
    "enlarge-image-on-hover"
    "nicer-checkboxes"
    "bigger-link-popup-preview"
    "image-cards"
    "readable-layout"
  ];

  communityPlugins = [
    "obsidian-git"
    "obsidian-importer"
    "table-editor-obsidian"
    "obsidian-vimrc-support"
  ];
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
            enabledCssSnippets = enabledSnippets;
          };

          extraFiles = {
            ".obsidian/community-plugins.json" = {
              text = builtins.toJSON communityPlugins;
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

                " Command palette — matches <leader><leader> in neovim
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
          }
          // builtins.listToAttrs (
            map (name: {
              name = ".obsidian/snippets/${name}.css";
              value = {
                text = snippets.${name};
              };
            }) (builtins.attrNames snippets)
          );
        };
      };
    };
  };
}
