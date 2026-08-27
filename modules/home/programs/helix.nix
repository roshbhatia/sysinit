{
  config,
  pkgs,
  ...
}:

let
  helixConfig = pkgs.fetchFromGitHub {
    owner = "mattwparas";
    repo = "helix-config";
    rev = "a101da0852932f10792f098dbb14ea88811985ff";
    hash = "sha256-N4Y78H9HDJernQkdH+24tylfl1bleBZewTB7Fk9LlGg=";
  };
  vimHx = pkgs.fetchFromGitHub {
    owner = "mattwparas";
    repo = "vim.hx";
    rev = "43f9c7fd26216c15fdf2455ac19ff0441a272876";
    hash = "sha256-ITssLSJGdhwlt7JBZKFaFrxwme9HyFOY6NrGpIY+1q4=";
  };
  oilHx = pkgs.fetchFromGitHub {
    owner = "Ra77a3l3-jar";
    repo = "oil.hx";
    rev = "fdd38520dc041d4314a7c5bc13520195b7f06cfa";
    hash = "sha256-cMpKLYVh5RkrbmKbigYdAjrF8J1wq6KxOfXoZ4AHLeE=";
  };
  notifyHx = pkgs.fetchFromGitHub {
    owner = "chuwy";
    repo = "notify.hx";
    rev = "0a328073e6d3e5041346374ae747c275ab8ce746";
    hash = "sha256-shKUVnJw2j0yYO+mTHsKie+d1VrJGWDTRul+PTpqlhs=";
  };
  helixConfigCogs = pkgs.runCommand "helix-config-cogs" { } ''
    mkdir -p "$out"
    cp -R "${helixConfig}/cogs/." "$out/"
    chmod -R u+w "$out"
    substituteInPlace "$out/recentf.scm" \
      --replace-fail \
        '(define RECENTF-FILE ".helix/recent-files.txt")' \
        '(define RECENTF-DIRECTORY (string-append (env-var "XDG_STATE_HOME") "/helix"))
    (define RECENTF-FILE (string-append RECENTF-DIRECTORY "/recent-files.scm"))' \
      --replace-fail \
        '(path-exists? ".helix")' \
        '(path-exists? RECENTF-DIRECTORY)' \
      --replace-fail \
        '(create-directory! ".helix")' \
        '(create-directory! RECENTF-DIRECTORY)'
  '';
  watcherLibrary = "libhelix_file_watcher${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}";
in
{
  home.sessionVariables.STEEL_HOME = "${config.xdg.dataHome}/steel";

  xdg.configFile = {
    "helix/cogs".source = helixConfigCogs;
    "helix/vim-hx".source = vimHx;
    "helix/oil".source = oilHx;
    "helix/notify".source = notifyHx;
    "helix/helix-file-watcher".source =
      "${pkgs.helix-file-watcher}/share/steel/cogs/helix-file-watcher";

    "helix/helix.scm".text = ''
      (require (only-in "cogs/file-tree.scm" create-file-tree))
      (require (only-in "cogs/recentf.scm" recentf-open-files))
      (require (only-in "oil/oil.scm"
                        oil oil-enter oil-up oil-root oil-refresh oil-save oil-close
                        oil-toggle-hidden oil-toggle-git-ignored oil-toggle-metadata
                        oil-yank oil-cut oil-paste oil-clipboard-clear))

      (provide create-file-tree recentf-open-files
               oil oil-enter oil-up oil-root oil-refresh oil-save oil-close
               oil-toggle-hidden oil-toggle-git-ignored oil-toggle-metadata
               oil-yank oil-cut oil-paste oil-clipboard-clear)
    '';

    "helix/init.scm".text = ''
      (require "cogs/keymaps.scm")
      (require "helix/ext.scm")
      (require (only-in "cogs/file-tree.scm" FILE-TREE FILE-TREE-KEYBINDINGS))
      (require (only-in "cogs/recentf.scm"
                        recentf-snapshot refresh-files flush-recent-files))
      (require "vim-hx/init.scm")
      (require (only-in "oil/oil.scm" oil-configure!))
      (require (only-in "helix-file-watcher/file-watcher.scm" spawn-watcher))

      (set-vim-keybindings!)
      (oil-configure! #false #false)
      (spawn-watcher 1000)
      (recentf-snapshot)

      (register-hook! 'document-opened
                      (lambda (_)
                        (refresh-files)
                        (flush-recent-files)))

      (define file-tree-keybindings (deep-copy-global-keybindings))
      (merge-keybindings file-tree-keybindings FILE-TREE-KEYBINDINGS)
      (set-global-buffer-or-extension-keymap (hash FILE-TREE file-tree-keybindings))
    '';
  };

  xdg.dataFile."steel/native/${watcherLibrary}".source =
    "${pkgs.helix-file-watcher}/lib/${watcherLibrary}";

  programs.helix = {
    enable = true;
    settings = {
      editor = {
        line-number = "relative";
        mouse = true;
        auto-save = true;
        bufferline = "multiple";
        true-color = true;
        undercurl = true;
        clipboard-provider = "pasteboard";
        cursorline = false;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "block";
        };

        file-picker = {
          parents = true;
        };

        whitespace = {
          render = {
            space = "none";
            tab = "none";
            newline = "none";
          };
        };

        lsp = {
          display-messages = true;
          auto-signature-help = true;
          display-inlay-hints = true;
          display-signature-help-docs = true;
        };

        statusline = {
          left = [
            "mode"
            "spinner"
            "file-name"
            "file-modification-indicator"
          ];
          center = [
            "file-type"
            "read-only-indicator"
            "file-encoding"
          ];
          right = [
            "diagnostics"
            "selections"
            "register"
            "position"
            "file-line-ending"
          ];
          separator = " | ";
          mode = {
            normal = " 󰄚 ";
            insert = " 󰓥 ";
            select = " 󱡃 ";
          };
        };
      };

      keys.normal = {
        "C-h" = "jump_view_left";
        "C-j" = "jump_view_down";
        "C-k" = "jump_view_up";
        "C-l" = "jump_view_right";
        K = "hover";
        U = "redo";
        "[" = {
          b = "goto_previous_buffer";
          c = "goto_prev_change";
          d = "goto_prev_diag";
        };
        "]" = {
          b = "goto_next_buffer";
          c = "goto_next_change";
          d = "goto_next_diag";
        };
        g = {
          c = "toggle_comments";
          O = "lsp_or_syntax_symbol_picker";
          r = {
            a = "code_action";
            i = "goto_implementation";
            n = "rename_symbol";
            r = "select_references_to_symbol_under_cursor";
            t = "goto_type_definition";
          };
        };
        space = {
          w = ":write-quit";
          s = "hsplit";
          v = "vsplit";
          q.q = ":quit!";
          c = {
            a = "code_action";
            D = "goto_definition";
            S = "lsp_or_syntax_workspace_symbol_picker";
            n = "goto_next_diag";
            p = "goto_prev_diag";
            j = "signature_help";
            o = "lsp_or_syntax_symbol_picker";
          };
          f = {
            f = "file_picker";
            g = "global_search";
            b = "buffer_picker";
            r = "last_picker";
            R = ":recentf-open-files";
            j = "jumplist_picker";
          };
          e = {
            f = ":oil";
            F = ":oil-root";
            t = ":create-file-tree";
            e = ":create-file-tree";
          };
          d = {
            c = "changed_file_picker";
            C = "changed_file_picker";
          };
        };
      };
    };
  };
}
