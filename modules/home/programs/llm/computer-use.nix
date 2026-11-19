{
  config,
  lib,
  pkgs,
  ...
}:
let
  signing = config.sysinit.codesign;
  # TCC grants follow a binary's path and signature, so macOS runs the signed copies.
  agentDesktop =
    if signing.enable then
      pkgs.symlinkJoin {
        name = "agent-desktop-stable-path";
        paths = [ pkgs.agent-desktop ];
        postBuild = ''
          for name in agent-desktop agent-desktop-macos-helper; do
            rm -f "$out/bin/$name"
            ln -s "${signing.signedBinDir}/$name" "$out/bin/$name"
          done
        '';
        meta.mainProgram = "agent-desktop";
      }
    else
      pkgs.agent-desktop;
in
{
  sysinit.codesign.binaries = lib.mkIf signing.enable {
    agent-desktop = lib.getExe pkgs.agent-desktop;
    agent-desktop-macos-helper = "${pkgs.agent-desktop}/bin/agent-desktop-macos-helper";
  };

  home.packages = [ agentDesktop ];

  sysinit.llm.mcp.additionalServers.agent-desktop = {
    command = lib.getExe agentDesktop;
    # The owner approved physical input; ref actions still try the accessibility API first.
    args = [
      "--headed"
      "mcp"
    ];
    description = "Operate native desktop apps through the OS accessibility tree";
  };
}
