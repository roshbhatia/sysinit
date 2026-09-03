{
  config,
  lib,
  pkgs,
  ...
}:

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

  nicerCheckboxes =
    builtins.replaceStrings
      [ "@checkboxIcon@" ]
      [
        (lib.escapeURL (builtins.readFile ./obsidian/snippets/nicer-checkboxes-check.svg))
      ]
      (builtins.readFile ./obsidian/snippets/nicer-checkboxes.css.tmpl);

  snippets = {
    "bullet-point-relationship-lines".source = ./obsidian/snippets/bullet-point-relationship-lines.css;
    "smaller-scrollbar".source = ./obsidian/snippets/smaller-scrollbar.css;
    "enlarge-image-on-hover".source = ./obsidian/snippets/enlarge-image-on-hover.css;
    "nicer-checkboxes".text = nicerCheckboxes;
    "bigger-link-popup-preview".source = ./obsidian/snippets/bigger-link-popup-preview.css;
    "image-cards".source = ./obsidian/snippets/image-cards.css;
    "readable-layout".source = ./obsidian/snippets/readable-layout.css;
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
              source = ./obsidian/obsidian.vimrc;
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
              value = snippets.${name};
            }) (builtins.attrNames snippets)
          );
        };
      };
    };
  };
}
