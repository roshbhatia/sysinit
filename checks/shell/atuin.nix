{
  lib,
  pkgs,
  home,
}:
let
  settings = pkgs.sysinit.writeJSON "atuin-settings.json" home.programs.atuin.settings;
  nushellLib = import ../../features/nushell/lib.nix { inherit lib; };
  nushellInit = pkgs.runCommand "atuin-check-init.nu" { } ''
    export HOME="$TMPDIR"
    ${lib.getExe pkgs.atuin} init nu ${lib.escapeShellArgs home.programs.atuin.flags} > "$out"
  '';
  nushellConfig = pkgs.writeText "atuin-check-config.nu" ''
    ${nushellLib.completers pkgs}
    $env.FZF_CTRL_R_COMMAND = ""
    source ${home.programs.fzf.package}/share/fzf/key-bindings.nu
    source ${home.programs.fzf.package}/share/fzf/completion.nu
    source ${nushellInit}
    source ${../../features/nushell/atuin-prompt.nu}
    $env.PROMPT_COMMAND = {|| "original-prompt " }
    $env.PROMPT_INDICATOR_VI_INSERT = ": "
    $env.PROMPT_COMMAND_RIGHT = ""
    $env.config.edit_mode = "vi"
    $env.config.show_banner = false
    $env.config.keybindings = ($env.config.keybindings | append {
      name: capture_buffer
      modifier: control
      keycode: char_x
      mode: [emacs vi_normal vi_insert]
      event: {send: executehostcommand, cmd: 'commandline | save --force $env.ATUIN_TEST_BUFFER'}
    })
  '';
in
assert home.programs.atuin.enable;
assert home.programs.atuin.daemon.enable;
assert home.programs.fzf.historyWidget.command == "";
assert builtins.all (shell: home.programs.atuin.${"enable${shell}Integration"}) [
  "Bash"
  "Fish"
  "Nushell"
];
(import ../lib/native.nix { inherit pkgs; }) {
  name = "atuin-local-history-and-threads";
  inputs = [
    pkgs.atuin
    pkgs.codex
    pkgs.claude-code
    pkgs.git
    pkgs.sysinit-utils
    (pkgs.python3.withPackages (ps: [
      ps.tomlkit
      ps.pyte
    ]))
  ];
  commands = [
    [
      "python3"
      "${./atuin.py}"
      "${settings}"
    ]
    [
      "python3"
      "${./atuin-nushell.py}"
      "${settings}"
      "${nushellConfig}"
    ]
    [
      "python3"
      "${../agents/threads-picker.py}"
      "${pkgs.sysinit-gotools}/bin/utils"
    ]
    [
      "nu"
      "--config"
      "${nushellConfig}"
      "${./atuin-bindings.nu}"
    ]
  ];
}
