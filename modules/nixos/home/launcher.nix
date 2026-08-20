{
  config,
  lib,
  pkgs,
  ...
}:

let
  themeLib = import ../../shared/theme-colors.nix { inherit lib; };
  c = themeLib.colorsOf config;

  wezterm = "${pkgs.wezterm}/bin/wezterm";
  swaymsg = "${pkgs.sway}/bin/swaymsg";
  jq = "${pkgs.jq}/bin/jq";
  fftabs = "${pkgs.sysinit-utils}/bin/firefox-tabs";
  # seshy is installed per-user rather than from a store path, the same way the
  # Hammerspoon launcher reaches it.
  sy = "/etc/profiles/per-user/${config.home.username}/bin/sy";

  # Every dynamic menu reads one tab-separated line per row. `jsonDecode` is a
  # Lua global elephant sets, but the provider's own README names it
  # `jsonDecodes`, and neither is covered by a test. A `@tsv` line and a
  # string split have no such ambiguity, and jq is already a dependency here.
  splitter = ''
    local function fields(line)
      local out = {}
      for part in string.gmatch(line .. "\t", "([^\t]*)\t") do
        out[#out + 1] = part
      end
      return out
    end

    local function lines(cmd)
      local handle = io.popen(cmd .. " 2>/dev/null")
      if handle == nil then
        return {}
      end
      local out = handle:read("*all")
      handle:close()
      local rows = {}
      for line in string.gmatch(out or "", "[^\n]+") do
        rows[#rows + 1] = fields(line)
      end
      return rows
    end
  '';

in
{
  home.packages = with pkgs; [
    walker
    wl-clipboard
    imagemagick
  ];

  # Menus are read from ~/.config/elephant/menus, and each provider reads its
  # own ~/.config/elephant/<provider>.toml, so there is nothing for the
  # top-level settings to carry.
  services.elephant.enable = true;

  xdg.configFile = {
    # The emoji picker. `history_when_empty = false` is the whole reason this
    # file exists: it ranks by what was picked before once something is typed,
    # and shows nothing on an empty query, so recents live in this sub-picker
    # and never reach the main list. `wl-copy` is the default command and is
    # named here because the copy is the point of the picker.
    "elephant/symbols.toml".text = ''
      history = true
      history_when_empty = false
      command = "wl-copy"
      locale = "en"
    '';

    "elephant/clipboard.toml".text = ''
      time_format = "relative"
    '';

    "elephant/desktopapplications.toml".text = ''
      history = true
    '';

    "elephant/menus/panes.lua".text = ''
      Name = "panes"
      NamePretty = "WezTerm Panes"
      Icon = "utilities-terminal"
      Action = "${wezterm} cli activate-pane --pane-id %VALUE%"
      SearchName = true
      History = true

      ${splitter}

      function GetEntries()
        local entries = {}
        local cmd = "${wezterm} cli list --format json | ${jq} -r '.[] | [.pane_id, (.workspace // \"default\"), (.title // .tab_title // \"pane\"), (.cwd // \"\")] | @tsv'"
        for _, row in ipairs(lines(cmd)) do
          if row[1] ~= nil and row[1] ~= "" then
            entries[#entries + 1] = {
              Text = row[2] .. ": " .. (row[3] or ""),
              Subtext = row[4] or "",
              Value = row[1],
            }
          end
        end
        return entries
      end
    '';

    "elephant/menus/sessions.lua".text = ''
      Name = "sessions"
      NamePretty = "Sessions"
      Icon = "utilities-terminal"
      Action = "${wezterm} cli spawn --new-window --workspace %VALUE%"
      SearchName = true
      History = true

      ${splitter}

      function GetEntries()
        local entries = {}
        local cmd = "${sy} list --json | ${jq} -r '.[] | [.name, (.repoCount // 0), (.path // \"\")] | @tsv'"
        for _, row in ipairs(lines(cmd)) do
          if row[1] ~= nil and row[1] ~= "" then
            entries[#entries + 1] = {
              Text = row[1],
              Subtext = (row[2] or "0") .. " repos",
              Value = row[1],
            }
          end
        end
        return entries
      end
    '';

    "elephant/menus/tabs.lua".text = ''
      Name = "tabs"
      NamePretty = "Firefox Tabs"
      Icon = "firefox"
      Action = "xdg-open %VALUE%"
      SearchName = true
      History = true

      ${splitter}

      function GetEntries()
        local entries = {}
        local cmd = "${fftabs} | ${jq} -r '.[] | [(.title // .url), (.url // \"\")] | @tsv'"
        for _, row in ipairs(lines(cmd)) do
          if row[2] ~= nil and row[2] ~= "" then
            entries[#entries + 1] = {
              Text = row[1],
              Subtext = row[2],
              Value = row[2],
            }
          end
        end
        return entries
      end
    '';

    # elephant ships a `windows` provider, but its only implementation is niri,
    # and on sway it returns an empty list rather than an error. This menu is
    # what makes Super+Tab work here.
    "elephant/menus/windows.lua".text = ''
      Name = "windows"
      NamePretty = "Windows"
      Icon = "preferences-system-windows"
      Action = "${swaymsg} '[con_id=%VALUE%] focus'"
      SearchName = true
      History = true

      ${splitter}

      function GetEntries()
        local entries = {}
        local cmd = "${swaymsg} -t get_tree | ${jq} -r '[recurse(.nodes[]?, .floating_nodes[]?) | select(.type == \"con\" or .type == \"floating_con\") | select(.name != null)] | .[] | [.id, .name, (.app_id // .window_properties.class // \"\")] | @tsv'"
        for _, row in ipairs(lines(cmd)) do
          if row[1] ~= nil and row[1] ~= "" then
            entries[#entries + 1] = {
              Text = row[2] or "",
              Subtext = row[3] or "",
              Value = row[1],
            }
          end
        end
        return entries
      end
    '';

    # `:` is the emoji prefix and `!` runs a command, both to match what the
    # Hammerspoon launcher already does on the other host. That costs the two
    # defaults walker ships on those keys: clipboard moves to `,` and the todo
    # provider is not configured here.
    "walker/config.toml".text = ''
      theme = "sysinit"
      close_when_open = true
      click_to_close = true
      selection_wrap = false

      [providers]
      default = [
        "desktopapplications",
        "menus:windows",
        "menus:panes",
        "menus:sessions",
        "menus:tabs",
        "calc",
      ]
      empty = [
        "desktopapplications",
        "menus:windows",
        "menus:panes",
        "menus:sessions",
      ]
      max_results = 50

      [placeholders]
      "default" = { input = "Search apps, windows, panes, tabs, : for emoji, ! to run", list = "No results" }
      "symbols" = { input = "Search emoji by name", list = "No emoji" }
      "runner" = { input = "Run a command", list = "No command" }
      "files" = { input = "Search files and folders by path", list = "No paths" }
      "clipboard" = { input = "Search the clipboard history", list = "Nothing held" }

      [[providers.prefixes]]
      prefix = ":"
      provider = "symbols"

      [[providers.prefixes]]
      prefix = "!"
      provider = "runner"

      [[providers.prefixes]]
      prefix = "/"
      provider = "files"

      [[providers.prefixes]]
      prefix = ","
      provider = "clipboard"

      [[providers.prefixes]]
      prefix = "="
      provider = "calc"

      [[providers.prefixes]]
      prefix = "@"
      provider = "websearch"

      [[providers.prefixes]]
      prefix = ";"
      provider = "providerlist"
    '';

    # Only style.css is written. walker reads a theme directory file by file and
    # falls back to the compiled-in default for anything absent, so the layout
    # and every item template stay upstream's.
    "walker/themes/sysinit/style.css".text = ''
      @define-color window_bg_color #${c.base00};
      @define-color accent_bg_color #${c.base0D};
      @define-color theme_fg_color #${c.base05};
      @define-color error_bg_color #${c.base08};
      @define-color error_fg_color #${c.base00};

      * {
        all: unset;
        font-family: "${config.sysinit.theme.font.monospace}", "Symbols Nerd Font Mono";
        font-size: 13px;
      }

      scrollbar {
        opacity: 0;
      }

      .box-wrapper {
        background: alpha(@window_bg_color, 0.96);
        border: 1px solid #${c.base02};
        border-radius: 0;
        padding: 16px;
      }

      .input {
        caret-color: @theme_fg_color;
        color: @theme_fg_color;
        background: #${c.base01};
        padding: 10px;
      }

      .input placeholder {
        color: #${c.base03};
      }

      .input selection {
        background: #${c.base02};
      }

      .list {
        color: @theme_fg_color;
      }

      .item-box {
        border-radius: 0;
        padding: 8px 10px;
      }

      child:selected .item-box,
      row:selected .item-box {
        background: #${c.base02};
        border-left: 2px solid @accent_bg_color;
      }

      .item-subtext {
        font-size: 12px;
        color: #${c.base04};
      }

      .item-image-text {
        font-size: 24px;
      }

      .symbols .item-image {
        font-size: 24px;
      }

      .calc .item-text {
        font-size: 20px;
        color: #${c.base0A};
      }

      .placeholder,
      .elephant-hint {
        color: #${c.base03};
      }

      .preview {
        border: 1px solid #${c.base02};
        border-radius: 0;
        color: @theme_fg_color;
      }

      .keybinds {
        padding-top: 10px;
        border-top: 1px solid #${c.base02};
        font-size: 12px;
        color: #${c.base04};
      }

      .keybind-bind {
        text-transform: lowercase;
        color: #${c.base03};
      }

      .keybind-label {
        padding: 2px 4px;
        border: 1px solid #${c.base03};
      }

      .error {
        padding: 10px;
        background: @error_bg_color;
        color: @error_fg_color;
      }
    '';
  };
}
