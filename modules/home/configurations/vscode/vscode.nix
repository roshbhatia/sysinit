{
  config,
  lib,
  pkgs,
  values,
  utils,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  stylixTargets = themes.stylixHelpers.enableStylixTargets ["vscode"];
in

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    profiles.default = {
      userSettings = {
        "[html]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[javascript]" = {
          "editor.defaultFormatter" = "vscode.typescript-language-features";
        };
        "[json]" = {
          "editor.defaultFormatter" = "vscode.json-language-features";
        };
        "[jsonc]" = {
          "editor.defaultFormatter" = "vscode.json-language-features";
        };
        "[lua]" = {
          "editor.defaultFormatter" = "JohnnyMorganz.stylua";
          "editor.formatOnSave" = true;
        };
        "[python]" = {
          "editor.formatOnType" = true;
        };
        "[typescript]" = {
          "editor.defaultFormatter" = "vscode.typescript-language-features";
        };
        "[yaml]" = {
          "editor.defaultFormatter" = "redhat.vscode-yaml";
        };

        "breadcrumbs.enabled" = true;
        "chaliceIcons.showArrows" = true;
        "chat.commandCenter.enabled" = false;
        "chat.extensionTools.enabled" = true;
        "chat.implicitContext.enabled" = {
          "panel" = "always";
        };
        "chat.mcp.discovery.enabled" = true;
        "chat.mcp.enabled" = true;
        "css.completion.triggerPropertyValueCompletion" = false;

        "custom-ui-style.electron" = {
          "frame" = false;
          "roundedCorners" = true;
          "titleBarStyle" = "customButtonsOnHover";
          "trafficLightPosition" = {
            "x" = 1000000;
            "y" = 1000000;
          };
        };
        "custom-ui-style.font.monospace" = "'Hack Nerd Font', 'Symbols Nerd Font'";
        "custom-ui-style.font.sansSerif" = "'Hack Nerd Font', 'Symbols Nerd Font'";
        "custom-ui-style.reloadWithoutPrompting" = true;
        "custom-ui-style.stylesheet" = {
          ".monaco-editor .margin-view-overlays" = {
            "padding-inline" = "5px";
          };
          ".monaco-workbench" = {
            "padding-top" = "0 !important";
          };
          ".monaco-workbench .activitybar" = {
            "& > .content" = {
              "& .composite-bar-container" = {
                "& .composite-bar" = {
                  "& .monaco-action-bar" = {
                    "& .action-item" = {
                      "& .codicon" = {
                        "&:hover" = {
                          "background-color" = "var(--vscode-activityBar-activeBorder)";
                          "transform" = "scale(1.1)";
                        };
                        "border-radius" = "12px";
                        "padding" = "8px";
                        "transition" = "all 0.2s ease-in-out";
                      };
                      "&.checked .codicon" = {
                        "background-color" = "var(--vscode-activityBar-activeBorder)";
                        "transform" = "scale(1.1)";
                      };
                      "align-items" = "center !important";
                      "display" = "flex !important";
                      "height" = "100% !important";
                      "justify-content" = "center !important";
                      "margin" = "0 !important";
                    };
                    "& .actions-container" = {
                      "align-items" = "center !important";
                      "display" = "flex !important";
                      "flex-direction" = "row !important";
                      "gap" = "12px !important";
                      "justify-content" = "center !important";
                      "margin" = "0 !important";
                      "padding" = "0 !important";
                    };
                    "align-items" = "center !important";
                    "display" = "flex !important";
                    "height" = "100% !important";
                    "justify-content" = "center !important";
                  };
                  "align-items" = "center !important";
                  "display" = "flex !important";
                  "height" = "100% !important";
                  "justify-content" = "center !important";
                  "width" = "auto !important";
                };
                "align-items" = "center !important";
                "display" = "flex !important";
                "height" = "100% !important";
                "justify-content" = "center !important";
                "width" = "auto !important";
              };
              "align-items" = "center !important";
              "display" = "flex !important";
              "height" = "100% !important";
              "justify-content" = "center !important";
              "width" = "100% !important";
            };
            "align-items" = "center !important";
            "background" = "var(--vscode-editorGroupHeader-tabsBackground) !important";
            "display" = "flex !important";
            "height" = "48px !important";
            "justify-content" = "center !important";
            "left" = "0 !important";
            "position" = "fixed !important";
            "right" = "0 !important";
            "top" = "0 !important";
            "width" = "100% !important";
            "z-index" = "1000 !important";
          };
          ".monaco-workbench .chat-view" = {
            "font-size" = "10px !important";
          };
          ".monaco-workbench .editor-group-container" = {
            "border-radius" = "12px";
            "margin-top" = "4px";
          };
          ".monaco-workbench .explorer-folders-view" = {
            "font-size" = "10px !important";
          };
          ".monaco-workbench .split-view-view" = {
            "border-radius" = "8px";
          };
          ".monaco-workbench .tab" = {
            "& when (@selected)" = {
              "box-shadow" = "none";
              "transform" = "translateY(-1px)";
            };
            "&:before" = {
              "border-radius" = "6px 6px 0 0 !important";
            };
            "border-radius" = "6px 6px 0 0 !important";
            "margin-right" = "4px";
            "overflow" = "hidden";
            "transition" = "all 0.2s ease-in-out";
          };
          ".monaco-workbench .tabs-container" = {
            "& > .tab" = {
              "& .tab-label" = {
                "margin-left" = "4px";
              };
              "margin-right" = "4px";
            };
            "padding-left" = "8px";
          };
        };
        "custom-ui-style.watch" = true;

        "debug.javascript.autoAttachFilter" = "smart";
        "debug.onTaskErrors" = "abort";
        "debug.terminal.clearBeforeReusing" = true;
        "diffEditor.codeLens" = true;

        "editor.accessibilitySupport" = "off";
        "editor.codeActionsOnSave" = {
          "source.fixAll" = "explicit";
        };
        "editor.cursorBlinking" = "phase";
        "editor.cursorSmoothCaretAnimation" = "on";
        "editor.cursorStyle" = "underline";
        "editor.cursorWidth" = 2;
        "editor.fontLigatures" =
          "'calt', 'liga', 'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'ss06', 'ss07', 'ss08', 'ss09'";
        "editor.fontVariations" = true;
        "editor.formatOnType" = true;
        "editor.glyphMargin" = true;
        "editor.inlineSuggest.enabled" = true;
        "editor.lineNumbers" = "on";
        "editor.minimap.autohide" = "mouseover";
        "editor.minimap.scale" = 2;
        "editor.minimap.showSlider" = "always";
        "editor.scrollbar.horizontal" = "visible";
        "editor.scrollbar.horizontalScrollbarSize" = 10;
        "editor.scrollbar.vertical" = "visible";
        "editor.scrollbar.verticalScrollbarSize" = 10;
        "editor.stickyScroll.enabled" = true;
        "editor.suggest.localityBonus" = true;
        "editor.suggest.preview" = true;
        "editor.suggestSelection" = "first";

        "extensions.experimental.affinity" = {
          "vscodevim.vim" = 1;
        };
        "extensions.ignoreRecommendations" = true;

        "files.associations" = {
          "*yaml.tmpl" = "yaml";
          "cleanup-orphans.sh" = "shellscript";
        };
        "files.autoGuessEncoding" = true;

        "git.autofetch" = true;
        "git.autofetchPeriod" = 15;
        "git.autoStash" = true;
        "git.closeDiffOnOperation" = true;
        "git.confirmSync" = false;
        "git.enableCommitSigning" = false;
        "git.ignoreRebaseWarning" = true;
        "git.mergeEditor" = true;
        "git.openRepositoryInParentFolders" = "always";
        "git.replaceTagsWhenPull" = true;

        "github.branchProtection" = true;
        "github.copilot.advanced" = {
          "useLanguageServer" = true;
        };
        "github.copilot.chat.agent.thinkingTool" = true;
        "github.copilot.chat.codeGeneration.useInstructionFiles" = true;
        "github.copilot.chat.codesearch.enabled" = true;
        "github.copilot.chat.commitMessageGeneration.instructions" = [
          {
            "text" =
              "You SHOULD use valid convential commit message formats, such as 'fix:', 'feat:', 'chore:', etc.";
          }
          {
            "text" = "You SHOULD use the imperative mood.";
          }
          {
            "text" = "You SHOULD use the present tense.";
          }
          {
            "text" = "You SHOULD be concise and clear.";
          }
          {
            "text" = "You MUST NOT add a body to the commit message.";
          }
        ];
        "github.copilot.chat.editor.temporalContext.enabled" = true;
        "github.copilot.chat.edits.temporalContext.enabled" = true;
        "github.copilot.chat.terminalChatLocation" = "terminal";
        "github.copilot.nextEditSuggestions.enabled" = false;
        "github.copilot.renameSuggestions.triggerAutomatically" = false;

        "githubPullRequests.createOnPublishBranch" = "never";
        "githubPullRequests.experimental.chat" = true;
        "githubPullRequests.pullBranch" = "always";

        "http.proxyStrictSSL" = false;
        "ipynb.pasteImagesAsAttachments.enabled" = false;

        "javascript.updateImportsOnFileMove.enabled" = "always";
        "js/ts.implicitProjectConfig.experimentalDecorators" = true;

        "jumpy2.achievements.active" = false;
        "jumpy2.customKeys" = "fjdkslaghrueiwoncmv";
        "jumpy2.jumperEmojis.active" = true;
        "jumpy2.jumperEmojis.jumperSet" = [ "" ];

        "markdown.preview.typographer" = true;
        "mergeEditor.diffAlgorithm" = "legacy";
        "redhat.telemetry.enabled" = false;

        "roo-cline.allowedCommands" = [
          "npm test"
          "npm install"
          "tsc"
          "git log"
          "git diff"
          "git show"
        ];
        "roo-cline.deniedCommands" = [ ];

        "searchPreview.search.excludeDirectories" = [
          "node_modules"
          ".git"
          "venv"
          "env"
          "dist"
          "build"
          "result"
        ];
        "searchPreview.search.excludePatterns" = [
          "**/*.min.js"
          "**/*.log"
          "**/*.lock"
          "**/package-lock.json"
          "**/*.jpeg"
          "**/*.png"
          "**/*.jpg"
        ];
        "searchPreview.search.maxResults" = 100;

        "security.workspace.trust.untrustedFiles" = "open";
        "terminal.external.osxExec" = "WezTerm.app";
        "terminal.integrated.fontLigatures.enabled" = true;
        "terminal.integrated.gpuAcceleration" = "off";

        "typescript.inlayHints.enumMemberValues.enabled" = true;
        "typescript.inlayHints.functionLikeReturnTypes.enabled" = true;
        "typescript.inlayHints.parameterNames.enabled" = "literals";
        "typescript.inlayHints.parameterTypes.enabled" = true;
        "typescript.inlayHints.propertyDeclarationTypes.enabled" = true;
        "typescript.inlayHints.variableTypes.enabled" = true;
        "typescript.preferences.importModuleSpecifier" = "relative";
        "typescript.preferences.includePackageJsonAutoImports" = "on";
        "typescript.updateImportsOnFileMove.enabled" = "always";

        "update.mode" = "manual";

        "vim.hlsearch" = true;
        "vim.incsearch" = true;
        "vim.leader" = "<space>";
        "vim.localleader" = ",";
        "vim.normalModeKeyBindings" = [
          {
            "before" = [
              "<leader>"
              "f"
              "f"
            ];
            "commands" = [ "search-preview.quickOpenWithPreview" ];
          }
          {
            "before" = [
              "<leader>"
              "q"
            ];
            "commands" = [ ":qa!" ];
          }
          {
            "before" = [
              "<localleader>"
              "L"
            ];
            "commands" = [ "workbench.action.showCommands" ];
          }
          {
            "before" = [
              "<leader>"
              "<leader>"
            ];
            "commands" = [ "workbench.action.showCommands" ];
          }
          {
            "before" = [
              "<leader>"
              "e"
              "n"
            ];
            "commands" = [ "editor.action.toggleLineNumbers" ];
          }
          {
            "before" = [
              "<localleader>"
              "e"
              "w"
            ];
            "commands" = [ "editor.action.toggleWordWrap" ];
          }
          {
            "before" = [
              "<leader>"
              "x"
            ];
            "commands" = [ "workbench.action.closeActiveEditor" ];
          }
          {
            "before" = [
              "<leader>"
              "w"
            ];
            "commands" = [
              "workbench.action.files.save"
              "workbench.action.closeActiveEditor"
            ];
          }
          {
            "before" = [
              "<leader>"
              "s"
            ];
            "commands" = [ "workbench.action.files.save" ];
          }
          {
            "before" = [
              "<localleader>"
              "s"
            ];
            "commands" = [ "workbench.action.files.saveWithoutFormatting" ];
          }
          {
            "before" = [
              "<localleader>"
              "b"
              "n"
            ];
            "commands" = [ "workbench.action.nextEditor" ];
          }
          {
            "before" = [
              "<localleader>"
              "b"
              "p"
            ];
            "commands" = [ "workbench.action.previousEditor" ];
          }
          {
            "before" = [
              "<localleader>"
              "r"
            ];
            "commands" = [ "workbench.action.files.revert" ];
          }
          {
            "before" = [ "u" ];
            "after" = [
              "g"
              "-"
            ];
          }
          {
            "before" = [ "U" ];
            "after" = [
              "g"
              "+"
            ];
          }
          {
            "before" = [ "m" ];
            "after" = [ "<Nop>" ];
          }
        ];
        "vim.visualModeKeyBindings" = [
          {
            "before" = [ "<Space>" ];
            "after" = [ "<Nop>" ];
          }
          {
            "before" = [ "m" ];
            "after" = [ "<Nop>" ];
          }
          {
            "before" = [ "H" ];
            "after" = [ "<" ];
            "silent" = true;
          }
          {
            "before" = [ "J" ];
            "after" = [ "}" ];
            "silent" = true;
          }
          {
            "before" = [ "K" ];
            "after" = [ "{" ];
            "silent" = true;
          }
          {
            "before" = [ "L" ];
            "after" = [ ">" ];
            "silent" = true;
          }
        ];
        "vim.useCtrlKeys" = true;
        "vim.useSystemClipboard" = true;

        "vscode_vibrancy.theme" = "Default Dark";
        "window.autoDetectColorScheme" = false;
        "window.commandCenter" = false;
        "window.customTitleBarVisibility" = "never";
        "window.density.editorTabHeight" = "compact";
        "window.systemColorTheme" = "dark";
        "window.titleBarStyle" = "native";

        "workbench.activityBar.location" = "top";
        "workbench.colorCustomizations" = { };
        "workbench.editor.editorActionsLocation" = "hidden";
        "workbench.editor.limit.enabled" = true;
        "workbench.editor.limit.value" = 5;
        "workbench.editorAssociations" = {
          "git-rebase-todo" = "default";
        };
        "workbench.layoutControl.enabled" = false;
        "workbench.panel.defaultLocation" = "right";
        "workbench.startupEditor" = "none";
        "workbench.statusBar.visible" = true;

        "yaml.schemas" = {
          "/Users/rbha18/.vscode-insiders/extensions/continue.continue-1.1.65-darwin-arm64/config-yaml-schema.json" =
            [
              ".continue/**/*.yaml"
            ];
        };
      };

      keybindings = [ ];

      extensions = with pkgs.vscode-extensions; [
        # Basic language support
        ms-python.python
        rust-lang.rust-analyzer
        golang.go

        # Git
        eamodio.gitlens

        # Vim
        vscodevim.vim

        # Nix
        bbenoist.nix
      ];
    };
  };
} // stylixTargets
