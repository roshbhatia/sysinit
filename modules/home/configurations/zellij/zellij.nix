{
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

  # Zellij theme configuration
  zellijTheme = {
    bg = semanticColors.background.primary;
    fg = semanticColors.foreground.primary;
    red = semanticColors.semantic.error;
    green = semanticColors.semantic.success;
    blue = semanticColors.semantic.info;
    yellow = semanticColors.semantic.warning;
    magenta = semanticColors.syntax.keyword;
    cyan = semanticColors.syntax.operator;
    black = semanticColors.background.secondary;
    white = semanticColors.foreground.primary;
    orange = semanticColors.syntax.number;
  };

  # Default layout configuration
  defaultLayout = {
    layout = {
      default_tab_template = {
        _children = [
          {
            pane = {
              size = 1;
              borderless = true;
              plugin = {
                location = "zellij:tab-bar";
              };
            };
          }
          { "children" = { }; }
          {
            pane = {
              size = 2;
              borderless = true;
              plugin = {
                location = "zellij:status-bar";
              };
            };
          }
        ];
      };
      _children = [
        {
          tab = {
            _props = {
              name = "Editor";
              focus = true;
            };
            _children = [
              {
                pane = {
                  command = "nvim";
                };
              }
            ];
          };
        }
        {
          tab = {
            _props = {
              name = "Git";
            };
            _children = [
              {
                pane = {
                  command = "lazygit";
                };
              }
            ];
          };
        }
        {
          tab = {
            _props = {
              name = "Files";
            };
            _children = [
              {
                pane = {
                  command = "yazi";
                };
              }
            ];
          };
        }
        {
          tab = {
            _props = {
              name = "Shell";
            };
            _children = [
              {
                pane = { };
              }
            ];
          };
        }
      ];
    };
  };

  # Development layout for focused coding
  devLayout = {
    layout = {
      default_tab_template = {
        _children = [
          {
            pane = {
              size = 1;
              borderless = true;
              plugin = {
                location = "zellij:tab-bar";
              };
            };
          }
          { "children" = { }; }
          {
            pane = {
              size = 2;
              borderless = true;
              plugin = {
                location = "zellij:status-bar";
              };
            };
          }
        ];
      };
      _children = [
        {
          tab = {
            _props = {
              name = "Code";
              focus = true;
            };
            _children = [
              {
                pane = {
                  _props = {
                    split_direction = "vertical";
                  };
                  _children = [
                    {
                      pane = {
                        _props = {
                          size = "70%";
                        };
                        command = "nvim";
                      };
                    }
                    {
                      pane = {
                        _props = {
                          size = "30%";
                        };
                      };
                    }
                  ];
                };
              }
            ];
          };
        }
        {
          tab = {
            _props = {
              name = "Test";
            };
            _children = [
              {
                pane = { };
              }
            ];
          };
        }
      ];
    };
  };
in
{
  programs.zellij = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

    settings = {
      theme = "${values.theme.colorscheme}-${values.theme.variant}";

      # UI configuration
      default_shell = "zsh";
      default_layout = "default";
      default_mode = "normal";

      # Mouse and scrollback
      mouse_mode = true;
      scroll_buffer_size = 10000;
      copy_command = "pbcopy"; # macOS clipboard
      copy_clipboard = "primary";

      # Simplified mode
      simplified_ui = false;
      pane_frames = true;

      # Session configuration
      session_serialization = false;
      pane_viewport_serialization = false;
      scrollback_lines_to_serialize = 10000;

      on_force_close = "quit";

      keybinds = {
        _props = {
          clear-defaults = true;
        };

        normal = {
          _children = [
            {
              bind = {
                _args = ["Ctrl h"];
                MoveFocus = ["Left"];
              };
            }
            {
              bind = {
                _args = ["Ctrl j"];
                MoveFocus = ["Down"];
              };
            }
            {
              bind = {
                _args = ["Ctrl k"];
                MoveFocus = ["Up"];
              };
            }
            {
              bind = {
                _args = ["Ctrl l"];
                MoveFocus = ["Right"];
              };
            }
            {
              bind = {
                _args = ["Ctrl Shift h"];
                Resize = ["Left" 3];
              };
            }
            {
              bind = {
                _args = ["Ctrl Shift j"];
                Resize = ["Down" 3];
              };
            }
            {
              bind = {
                _args = ["Ctrl Shift k"];
                Resize = ["Up" 3];
              };
            }
            {
              bind = {
                _args = ["Ctrl Shift l"];
                Resize = ["Right" 3];
              };
            }
            {
              bind = {
                _args = ["Ctrl v"];
                NewPane = ["Right"];
              };
            }
            {
              bind = {
                _args = ["Ctrl s"];
                NewPane = ["Down"];
              };
            }
            {
              bind = {
                _args = ["Ctrl w"];
                CloseFocus = {};
              };
            }
            {
              bind = {
                _args = ["Ctrl t"];
                NewTab = {};
              };
            }
            {
              bind = {
                _args = ["Ctrl 1"];
                GoToTab = [1];
              };
            }
            {
              bind = {
                _args = ["Ctrl 2"];
                GoToTab = [2];
              };
            }
            {
              bind = {
                _args = ["Ctrl 3"];
                GoToTab = [3];
              };
            }
            {
              bind = {
                _args = ["Ctrl 4"];
                GoToTab = [4];
              };
            }
            {
              bind = {
                _args = ["Ctrl 5"];
                GoToTab = [5];
              };
            }
            {
              bind = {
                _args = ["Ctrl 6"];
                GoToTab = [6];
              };
            }
            {
              bind = {
                _args = ["Ctrl 7"];
                GoToTab = [7];
              };
            }
            {
              bind = {
                _args = ["Ctrl 8"];
                GoToTab = [8];
              };
            }
            {
              bind = {
                _args = ["Cmd t"];
                NewTab = {};
              };
            }
            {
              bind = {
                _args = ["Cmd 1"];
                GoToTab = [1];
              };
            }
            {
              bind = {
                _args = ["Cmd 2"];
                GoToTab = [2];
              };
            }
            {
              bind = {
                _args = ["Cmd 3"];
                GoToTab = [3];
              };
            }
            {
              bind = {
                _args = ["Cmd 4"];
                GoToTab = [4];
              };
            }
            {
              bind = {
                _args = ["Cmd 5"];
                GoToTab = [5];
              };
            }
            {
              bind = {
                _args = ["Cmd 6"];
                GoToTab = [6];
              };
            }
            {
              bind = {
                _args = ["Cmd 7"];
                GoToTab = [7];
              };
            }
            {
              bind = {
                _args = ["Cmd 8"];
                GoToTab = [8];
              };
            }
            {
              bind = {
                _args = ["Cmd Shift Left"];
                GoToPreviousTab = {};
              };
            }
            {
              bind = {
                _args = ["Cmd Shift Right"];
                GoToNextTab = {};
              };
            }
            {
              bind = {
                _args = ["h"];
                MoveFocus = ["Left"];
              };
            }
            {
              bind = {
                _args = ["j"];
                MoveFocus = ["Down"];
              };
            }
            {
              bind = {
                _args = ["k"];
                MoveFocus = ["Up"];
              };
            }
            {
              bind = {
                _args = ["l"];
                MoveFocus = ["Right"];
              };
            }

            {
              bind = {
                _args = ["|"];
                NewPane = ["Right"];
              };
            }
            {
              bind = {
                _args = ["-"];
                NewPane = ["Down"];
              };
            }
            {
              bind = {
                _args = ["x"];
                CloseFocus = {};
              };
            }
            {
              bind = {
                _args = ["1"];
                GoToTab = [1];
              };
            }
            {
              bind = {
                _args = ["2"];
                GoToTab = [2];
              };
            }
            {
              bind = {
                _args = ["3"];
                GoToTab = [3];
              };
            }
            {
              bind = {
                _args = ["4"];
                GoToTab = [4];
              };
            }
            {
              bind = {
                _args = ["5"];
                GoToTab = [5];
              };
            }
            {
              bind = {
                _args = ["t"];
                NewTab = {};
              };
            }

            {
              bind = {
                _args = ["r"];
                SwitchToMode = ["Resize"];
              };
            }
            {
              bind = {
                _args = ["s"];
                SwitchToMode = ["Scroll"];
              };
            }
            {
              bind = {
                _args = ["q"];
                Quit = {};
              };
            }
          ];
        };

        # Resize mode
        resize = {
          _children = [
            {
              bind = {
                _args = ["h"];
                Resize = ["Left"];
              };
            }
            {
              bind = {
                _args = ["j"];
                Resize = ["Down"];
              };
            }
            {
              bind = {
                _args = ["k"];
                Resize = ["Up"];
              };
            }
            {
              bind = {
                _args = ["l"];
                Resize = ["Right"];
              };
            }
            {
              bind = {
                _args = ["Esc"];
                SwitchToMode = ["Normal"];
              };
            }
          ];
        };

        # Scroll mode
        scroll = {
          _children = [
            {
              bind = {
                _args = ["j"];
                ScrollDown = {};
              };
            }
            {
              bind = {
                _args = ["k"];
                ScrollUp = {};
              };
            }
            {
              bind = {
                _args = ["Esc"];
                SwitchToMode = ["Normal"];
              };
            }
          ];
        };
      };
    };

    layouts = {
      default = defaultLayout;
      dev = devLayout;
    };

    themes = {
      "${values.theme.colorscheme}-${values.theme.variant}" = {
        fg = zellijTheme.fg;
        bg = zellijTheme.bg;
        red = zellijTheme.red;
        green = zellijTheme.green;
        blue = zellijTheme.blue;
        yellow = zellijTheme.yellow;
        magenta = zellijTheme.magenta;
        cyan = zellijTheme.cyan;
        black = zellijTheme.black;
        white = zellijTheme.white;
        orange = zellijTheme.orange;
      };
    };
  };
}
