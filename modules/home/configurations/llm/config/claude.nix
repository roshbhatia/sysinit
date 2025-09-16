{ lib, values, ... }:
let
  mcpServers = import ../shared/mcp-servers.nix;
  claudeEnabled = values.llm.claude.enabled or false;
in
lib.mkIf claudeEnabled {
  home.file = {
    "claude/settings.json" = {
      text = builtins.toJSON {
        includeCoAuthoredBy = false;
        permissions = {
          defaultMode = "plan";
          toolPermissions = {
            Bash = "prompt";
            Edit = "allow";
            Read = "allow";
            Write = "prompt";
          };
        };

        context = {
          compression = true;
          description = "Compress context to save credits";
        };

        sandbox = {
          mode = "secure";
          allow_sudo = false;
          disable_safety_checks = false;
        };

        model = "claude-3-5-sonnet";

        features = {
          deep_thinking = true;
          image_processing = true;
          context_management = true;
        };

        inherit (mcpServers) servers;
      };
      force = true;
    };
  };
}
