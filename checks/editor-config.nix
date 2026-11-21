{ pkgs }:
let
  weztermRoot = pkgs.sysinit-wezterm-source;
  weztermLua = pkgs.sysinit-wezterm-lua;
  nvimRoot = pkgs.sysinit-nvim-source;
in
(import ./native.nix { inherit pkgs; }) {
  name = "editor-config-check";
  inputs = [
    pkgs.git
    (pkgs.lua5_4.withPackages (ps: [ ps.cjson ]))
    pkgs.neovim
    pkgs.deadnix
    pkgs.statix
    pkgs.nodejs_22
    pkgs.wezterm
  ];
  environment = {
    SYSINIT_NVIM_OCTO = pkgs.vimPlugins.octo-nvim;
    SYSINIT_NVIM_CONFIG = nvimRoot;
    SYSINIT_NVIM_DIFFVIEW = pkgs.vimPlugins.diffview-nvim;
    SYSINIT_NVIM_NU_PARSER = pkgs.vimPlugins.nvim-treesitter.grammarPlugins.nu;
    SYSINIT_NVIM_NONE_LS = pkgs.vimPlugins.none-ls-nvim;
    SYSINIT_NVIM_NU_QUERIES = pkgs.vimPlugins.nvim-treesitter.queries.nu;
  };
  commands = [
    [
      "nvim"
      "--headless"
      "--clean"
      "-u"
      "NONE"
      "--cmd"
      "set runtimepath^=${pkgs.vimPlugins.plenary-nvim}"
      "-c"
      "runtime plugin/plenary.vim"
      "-c"
      "PlenaryBustedDirectory ${nvimRoot}/checks/neovim { minimal_init = '${nvimRoot}/checks/neovim.lua', sequential = true }"
    ]
    [
      "lua"
      "${weztermRoot}/checks/wezterm.lua"
      "${weztermLua}"
      "${weztermRoot}/checks/fixtures/wezterm-plugin"
    ]
    [
      "lua"
      "${./hammerspoon.lua}"
      "${../modules/darwin/home/hammerspoon}"
    ]
    [
      "lua"
      "${pkgs.command-palette-source}/tests/panel.lua"
      "${pkgs.command-palette-source}"
    ]
    [
      "lua"
      "${pkgs.command-palette-source}/tests/lifecycle.lua"
      "${pkgs.command-palette-source}"
    ]
    [
      "lua"
      "${pkgs.command-palette-source}/tests/sources.lua"
      "${pkgs.command-palette-source}"
    ]
    [
      "node"
      "${pkgs.command-palette-source}/tests/actions.mjs"
      "${pkgs.command-palette-source}/command_palette/page/actions.js"
      "${pkgs.command-palette-source}/command_palette/page/panel.html"
    ]
    [
      "nu"
      "--no-config-file"
      "${./.}/editor-config.nu"
      "${weztermLua}"
      "${weztermRoot}"
      "${weztermRoot}/checks/fixtures/wezterm/config.json"
      "${weztermRoot}/checks/fixtures/wezterm/env.json"
    ]
  ];
}
