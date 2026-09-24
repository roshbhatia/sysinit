{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  disabledMcpServers = [ ];

  schemaDir = "${render.schemas}";

  defaultInstructions = kit.mkInstructionsWithStyle {
    harness = "opencode";
    skillsRoot = "~/.claude/skills";
  };

  render = import ./render.nix { inherit pkgs lib; };
  plugins = pkgs.runCommand "opencode-sysinit-plugins" { nativeBuildInputs = [ pkgs.bun ]; } ''
    bun build ${./plugins}/sysinit-notify.ts ${./plugins}/sysinit-edits.ts --target=bun --outdir "$out"
  '';

  opencodeConfig = render.main // {
    mcp = llmLib.mcp.formatForOpencode disabledMcpServers (kit.mcpServers.serversFor "opencode");

  };

  subagentFiles = lib.mapAttrs' (
    name: agentConfig:
    lib.nameValuePair "opencode/agents/${name}.md" {
      text = llmLib.instructions.formatSubagentAsMarkdown {
        inherit name;
        config = agentConfig;
        harness = "opencode";
      };
    }
  ) llmLib.instructions.subagentDefs;

in
{
  sysinit.llm.managedFiles = {
    opencode = {
      path = ".config/opencode/opencode.json";
      format = "json";
      content = opencodeConfig;
      schema = null;
      inherit (render) enforce retire;
    };
    opencode-tui = {
      path = ".config/opencode/cli.json";
      format = "json";
      content = render.tui;
      schema = "${schemaDir}/cli.json";
      retire = render.retiredTui;
    };
  };

  xdg.configFile = lib.mkMerge [
    {
      "opencode/sysinit-notify.js" = {
        source = "${plugins}/sysinit-notify.js";
        force = true;
      };
      "opencode/plugins/sysinit-edits.js".source = "${plugins}/sysinit-edits.js";
      "carapace/bridge/zsh/.zshrc".text = lib.mkAfter ''
        fpath=(${pkgs.opencode}/share/zsh/site-functions $fpath)
        autoload -Uz _opencode
        compdef _opencode opencode opencode2
      '';
      "carapace/specs/opencode.yaml".text = ''
        name: opencode
        description: OpenCode v2 terminal agent
        parsing: disabled
        completion:
          positionalany: ["$carapace.bridge.Zsh([opencode])"]
      '';
      "carapace/specs/opencode2.yaml".text = ''
        name: opencode2
        description: OpenCode v2 terminal agent
        parsing: disabled
        completion:
          positionalany: ["$carapace.bridge.Zsh([opencode])"]
      '';
      "opencode/AGENTS.md" = {
        text = defaultInstructions;
        force = true;
      };
    }
    subagentFiles
  ];

}
