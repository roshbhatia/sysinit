{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  user = config.sysinit.user.username;
  signedBin = "${config.users.users.${user}.home}/${(import ../shared/codesign.nix).signedBinDir}";
  home = config.home-manager.users.${config.sysinit.user.username};
  weztermApp = "${home.home.homeDirectory}/${home.targets.darwin.copyApps.directory}/WezTerm.app";
  komorebic = "${signedBin}/komorebic";
  sketchybar = "${pkgs.sketchybar}/bin/sketchybar";
  notifyMode = mode: "${sketchybar} --trigger komorebi_mode_changed MODE=${mode}";
  notifyWorkspace = "${sketchybar} --trigger komorebi_workspace_change";
  command = name: "${komorebic} ${name}";
  app = id: {
    kind = "Exe";
    inherit id;
    matching_strategy = "Equals";
  };
  byTitle = id: {
    kind = "Title";
    inherit id;
    matching_strategy = "Contains";
  };
  initialRule = app;
  workspace = name: layout: rules: {
    inherit name layout;
    initial_workspace_rules = rules;
  };
  workspaces = [
    (workspace "1" "BSP" [ ])
    (workspace "2" "BSP" [ ])
    (workspace "3" "BSP" [ ])
    (workspace "C" "BSP" [
      (initialRule "Discord")
      (initialRule "Slack")
    ])
    (workspace "M" "BSP" [
      (initialRule "Books")
      (initialRule "Music")
      (initialRule "Podcasts")
      [
        (app "Audible")
        (byTitle "Audible Cloud Player")
      ]
    ])
  ];
  floatingApplications = map app [
    "System Settings"
    "1Password"
    "Keychain Access"
    "Finder"
    "Messages"
    "FaceTime"
    "Calculator"
    "Activity Monitor"
    "Disk Utility"
    "Font Book"
    "Console"
    "Stickies"
    "Archive Utility"
    "Screen Sharing"
    "Image Capture"
    "Audio MIDI Setup"
    "Okta Verify"
    "Hammerspoon"
  ];
  modeChange = mode: label: ":: ${mode} @ : ${notifyMode label}";
  skhdrc = pkgs.writeText "skhdrc" ''
    ${modeChange "default" "MAIN"}
    alt - enter : ${pkgs.sysinit-utils}/bin/wezspawn --wezterm ${pkgs.wezterm}/bin/wezterm --gui-app ${lib.escapeShellArg weztermApp}
    alt - t : ${command "change-layout Columns"}
    alt - a : ${command "change-layout UltrawideVerticalStack"}
    alt - s : ${command "change-layout VerticalStack"}
    alt - w : ${command "change-layout HorizontalStack"}
    alt - e : ${command "change-layout BSP"}
    alt + shift - space : ${command "toggle-float"}
    alt - x ; move
    alt - g ; locked
    alt - r ; resize
    alt - h : ${command "focus left"}
    alt - j : ${command "focus down"}
    alt - k : ${command "focus up"}
    alt - l : ${command "focus right"}
    alt + shift - h : ${command "move left"}
    alt + shift - j : ${command "move down"}
    alt + shift - k : ${command "move up"}
    alt + shift - l : ${command "move right"}
    alt - 1 : ${command "focus-workspace 0"}; ${notifyWorkspace}
    alt - 2 : ${command "focus-workspace 1"}; ${notifyWorkspace}
    alt - 3 : ${command "focus-workspace 2"}; ${notifyWorkspace}
    alt - c : ${command "focus-workspace 3"}; ${notifyWorkspace}
    alt - m : ${command "focus-workspace 4"}; ${notifyWorkspace}
    alt + shift - 1 : ${command "move-to-workspace 0"}; ${notifyWorkspace}
    alt + shift - 2 : ${command "move-to-workspace 1"}; ${notifyWorkspace}
    alt + shift - 3 : ${command "move-to-workspace 2"}; ${notifyWorkspace}
    alt + shift - c : ${command "move-to-workspace 3"}; ${notifyWorkspace}
    alt + shift - m : ${command "move-to-workspace 4"}; ${notifyWorkspace}
    alt - tab : ${command "cycle-workspace next"}; ${notifyWorkspace}
    alt + shift - tab : ${command "cycle-workspace previous"}; ${notifyWorkspace}
    alt - p : ${command "focus-last-workspace"}; ${notifyWorkspace}
    alt - f : ${command "toggle-monocle"}
    alt + shift - f : ${command "toggle-monocle"}

    ${modeChange "locked" "LOCKED"}
    alt - escape ; default

    ${modeChange "move" "MOVE"}
    escape ; default
    enter ; default
    alt - escape ; default
    alt - h : ${command "move left"}
    alt - j : ${command "move down"}
    alt - k : ${command "move up"}
    alt - l : ${command "move right"}

    ${modeChange "resize" "RESIZE"}
    escape ; default
    enter ; default
    alt - escape ; default
    h : ${command "resize-axis horizontal decrease"}
    j : ${command "resize-axis vertical increase"}
    k : ${command "resize-axis vertical decrease"}
    l : ${command "resize-axis horizontal increase"}
    alt - h : ${command "resize-axis horizontal decrease"}
    alt - j : ${command "resize-axis vertical increase"}
    alt - k : ${command "resize-axis vertical decrease"}
    alt - l : ${command "resize-axis horizontal increase"}
  '';
in
{
  imports = [ inputs.komorebi.darwinModules.default ];

  services.komorebi = {
    enable = true;
    config = {
      cross_monitor_move_behaviour = "Insert";
      default_container_padding = 16;
      default_workspace_padding = 16;
      display_index_preferences = {
        "0" = "Built-in Retina Display";
        "1" = "LG HDR 4K";
        "2" = "DELL U3824DW";
      };
      floating_applications = floatingApplications;
      floating_layer_behaviour = "Float";
      global_work_area_offset = {
        left = 16;
        top = 62;
        right = 16;
        bottom = 14;
      };
      monitors = [
        {
          workspace_padding = 16;
          container_padding = 16;
          work_area_offset = {
            left = 16;
            top = 62;
            right = 16;
            bottom = 14;
          };
          inherit workspaces;
        }
        {
          workspace_padding = 16;
          container_padding = 16;
          work_area_offset = {
            left = 400;
            top = 200;
            right = 400;
            bottom = 200;
          };
          inherit workspaces;
        }
        {
          workspace_padding = 16;
          container_padding = 16;
          work_area_offset = {
            left = 128;
            top = 62;
            right = 128;
            bottom = 14;
          };
          inherit workspaces;
        }
      ];
      resize_delta = 72;
    };
  };

  launchd.user.agents.skhd = {
    serviceConfig = {
      Label = "org.sysinit.skhd";
      ProgramArguments = [
        "${signedBin}/skhd"
        "--config"
        "${skhdrc}"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/skhd-sysinit.log";
      StandardErrorPath = "/tmp/skhd-sysinit.log";
    };
  };
}
