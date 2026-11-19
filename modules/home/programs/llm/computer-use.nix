{
  config,
  lib,
  pkgs,
  ...
}:
let
  signing = config.sysinit.codesign;

  # TCC grants follow a binary's path and signature, so macOS runs the signed copies.
  signed = {
    agent-desktop = lib.getExe pkgs.agent-desktop;
    agent-desktop-macos-helper = "${pkgs.agent-desktop}/bin/agent-desktop-macos-helper";
    relay-engine = "${pkgs.screen-relay}/libexec/screen-relay/relay-engine";
  };

  stablePath =
    package: names:
    pkgs.symlinkJoin {
      name = "${package.pname}-stable-path";
      paths = [ package ];
      postBuild = lib.concatMapStrings (name: ''
        rm -f "$out/bin/${name}"
        ln -s "${signing.signedBinDir}/${name}" "$out/bin/${name}"
      '') names;
      meta.mainProgram = package.meta.mainProgram;
    };

  agentDesktop =
    if signing.enable then
      stablePath pkgs.agent-desktop [
        "agent-desktop"
        "agent-desktop-macos-helper"
      ]
    else
      pkgs.agent-desktop;

  # screen-relay finds relay-engine on PATH; on Linux its wrapper already provides it.
  screenRelay =
    if signing.enable then stablePath pkgs.screen-relay [ "relay-engine" ] else pkgs.screen-relay;
in
{
  home.packages = [
    agentDesktop
    screenRelay
  ];

  sysinit = {
    codesign.binaries = lib.mkIf signing.enable signed;

    llm.instructions.skillRoutes = [
      {
        intent = "Desktop computer use, instead of a harness's built-in computer-use or screenshot tools";
        skills = [ "computer-use" ];
      }
    ];

    llm.mcp.additionalServers.agent-desktop = {
      command = lib.getExe agentDesktop;
      # The owner approved physical input; ref actions still try the accessibility API first.
      args = [
        "--headed"
        "mcp"
      ];
      description = "Operate native desktop apps through the OS accessibility tree";
    };
  };
}
