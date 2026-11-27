{
  config,
  inputs,
  lib,
  pkgs,
  values ? { },
  ...
}:

let
  themeLib = import ../theme/colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  paths = import ../../modules/lib/paths.nix { inherit lib; };
  themeConfig = config.sysinit.theme;
  c = themeColors;
  palette = import ../theme/terminal-palette.nix c;
  luaSource = inputs.sysinit-wezterm.lib.luaSource pkgs;
  weztermMacOS = "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/WezTerm.app/Contents/MacOS";
  weztermLauncher = pkgs.writeShellScriptBin "wezterm" ''
    exec ${lib.escapeShellArg "${weztermMacOS}/wezterm"} "$@"
  '';

  paneName = pkgs.writeShellApplication {
    name = "wezterm-pane-name";
    runtimeInputs = [ pkgs.lua5_4 ];
    text = ''
      if [[ -z ''${WEZTERM_PANE:-} ]]; then
        echo "wezterm-pane-name: must run inside a WezTerm pane" >&2
        exit 2
      fi

      lua - ${luaSource}/sysinit/pkg/ui/badges.lua "$WEZTERM_PANE" <<'LUA'
      local badges = dofile(arg[1])
      local pane_id = tonumber(arg[2])
      if not pane_id then
        io.stderr:write("wezterm-pane-name: invalid WEZTERM_PANE value\n")
        os.exit(2)
      end
      print(badges.name(pane_id))
      LUA
    '';
  };

  sshCfg = config.sysinit.git.ssh;
  sshAgentSocket =
    if lib.hasPrefix "~/" sshCfg.agentSocket then
      config.home.homeDirectory + lib.removePrefix "~" sshCfg.agentSocket
    else
      sshCfg.agentSocket;

in
{

  imports = [
    inputs.sysinit-wezterm.homeManagerModules.default
    ../review/home.nix
  ];
  # The CLI launches the GUI beside its own executable.
  home.packages = [
    paneName
    (lib.hiPrio pkgs.sysinit-ty)
  ]
  ++ lib.optional (pkgs.stdenv.hostPlatform.isDarwin && config.targets.darwin.copyApps.enable) (
    lib.hiPrio weztermLauncher
  );
  programs.wezterm.extraConfig = lib.mkForce ''
    local links = dofile("${./links.lua}")
    local review = links.setup(wezterm.json_parse(${
      builtins.toJSON (
        builtins.toJSON {
          bin = "${config.home.profileDirectory}/bin";
          file = lib.getExe pkgs.file;
          home = config.home.homeDirectory;
          path = paths.getPathString config.home.username config.home.homeDirectory;
        }
      )
    }))
    package.path = package.path .. ";${luaSource}/?.lua;${luaSource}/?/init.lua"
    local config = links.build_config(require("sysinit.pkg.bootstrap").build, review)
    config.visual_bell_on_copy = true
    links.configure_mouse(config)
    links.configure_hyperlinks(config)
    ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      dofile("${./clipboard.lua}")(config)
    ''}
    return config
  '';
  programs.sysinit-wezterm = {
    enable = true;
    persistence = {
      enable = true;
      service = values.wezterm.remoteMux or false;
      # The copied bundle keeps one path and one signing identity across updates.
      muxBinary = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "${weztermMacOS}/wezterm-mux-server";
    };
    settings = {
      unsetEnvironmentVariables = [ "NO_COLOR" ];
      persistentRemoteHosts = [
        "arrakis"
        "arrakis.local"
        "lv426"
        "lv426.local"
      ];

      agents = import ../../modules/home/programs/llm/harnesses/deck-patterns.nix;

      # Saved in plain text under the 0700 recovery directory; history copies omit it.
      persistence = {
        scrollback_lines = 10000;
        exclude_workspaces = lib.optional config.sysinit.queue.enable "task-queue";
      };

      agentResume =
        lib.mapAttrs
          (
            _n: h:
            let
              inherit (h.launch.fullAccess) args env;
              assignments = lib.mapAttrsToList (name: value: "${name}=${value}") env;
            in
            lib.optionals (assignments != [ ]) ([ "env" ] ++ assignments)
            ++ [ h.command ]
            ++ args
            ++ h.launch.resumeArgs
          )
          (
            lib.filterAttrs (_n: h: h ? launch.resumeArgs) (
              import ../../modules/home/programs/llm/harnesses/registry.nix
            )
          );

      agentIdentity = lib.mapAttrs (_n: h: {
        inherit (h) label glyph;
      }) (import ../../modules/home/programs/llm/harnesses/registry.nix);

      bin = "${config.home.profileDirectory}/bin";
      shell = import ../../modules/shared/terminal-shell.nix config;
      ssh = lib.optionalAttrs sshCfg.use1PasswordAgent { agent_socket = sshAgentSocket; };
      font = {
        inherit (themeConfig.font) monospace;
        inherit (themeConfig.font) symbols;
      };
      transparency = {
        inherit (themeConfig.transparency) opacity;
        inherit (themeConfig.transparency) blur;
      };
      colors = palette // {
        cursor_border = "#${c.base05}";
        split = "#${c.base0D}";
        tab_bar = {
          background = "#${c.base01}";
          active_tab = {
            bg_color = "#${c.base02}";
            fg_color = "#${c.base05}";
          };
          inactive_tab = {
            bg_color = "#${c.base01}";
            fg_color = "#${c.base04}";
          };
          inactive_tab_hover = {
            bg_color = "#${c.base02}";
            fg_color = "#${c.base05}";
          };
          new_tab = {
            bg_color = "#${c.base01}";
            fg_color = "#${c.base04}";
          };
          new_tab_hover = {
            bg_color = "#${c.base02}";
            fg_color = "#${c.base05}";
          };
        };
      };
      spawn.commands = {
        ssh = lib.getExe' pkgs.openssh "ssh";
        mosh = lib.getExe' pkgs.mosh "mosh";
      };
      picker = {
        placement = "pane";
        workspace_slots = lib.optionalAttrs config.sysinit.queue.enable {
          task-queue = 99;
        };
        hidden_workspaces = lib.optionalAttrs config.sysinit.queue.enable {
          task-queue = true;
        };
        providers = [
          {
            name = "tether";
            key = "@";
            manifest = "${pkgs.tether-picker}/share/wezterm/providers/tether.json";
          }
          {
            name = "seshy";
            key = "$";
            manifest = "${pkgs.seshy-picker}/share/wezterm/providers/seshy.json";
          }
          {
            name = "zoxide";
            key = "%";
            manifest = "${pkgs.zoxide-picker}/share/wezterm/providers/zoxide.json";
          }
        ]
        ++ lib.optionals config.sysinit.queue.enable [
          {
            name = "tq";
            palette_title = "Queue: browse attempts";
            manifest = "${pkgs.tq-picker}/share/wezterm/providers/tq.json";
          }
        ];
      };
      cwd_aliases.sy = config.sysinit.paths.resolved.seshySessions;
      passthrough_procs = [
        "caffeinate"
      ];
    };
    environment = {

      PATH = paths.getPathString config.home.username config.home.homeDirectory;
      # A long-lived mux outlives the store path of any one terminfo build.
      TERMINFO_DIRS = "${config.home.profileDirectory}/share/terminfo";
    };
  };

}
