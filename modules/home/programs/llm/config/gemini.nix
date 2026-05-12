{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  geminiSettingsToml = ''
    # MCP Servers
    [mcpServers]
    ${llmLib.mcp.formatForGemini kit.mcpServers.servers}
  '';

  # Gemini extensions vendored from this repo. Each entry is a directory under
  # ./gemini-extensions/<name>/ containing at minimum gemini-extension.json.
  # All files in each extension directory are installed verbatim under
  # ~/.gemini/extensions/<name>/.
  geminiExtensions = {
    openspec-awareness = ./gemini-extensions/openspec-awareness;
  };

  extensionFiles = lib.foldl' (
    acc: name: acc // (mkExtensionFiles name geminiExtensions.${name})
  ) { } (builtins.attrNames geminiExtensions);

  mkExtensionFiles =
    name: dir:
    let
      contents = builtins.readDir dir;
      mkEntry =
        fname: _:
        lib.nameValuePair ".gemini/extensions/${name}/${fname}" {
          source = dir + "/${fname}";
          force = true;
        };
    in
    lib.mapAttrs' mkEntry contents;
in
{
  xdg.configFile = {
    "gemini/settings.toml" = {
      text = geminiSettingsToml;
      force = true;
    };
    "gemini/GEMINI.md" = {
      text = kit.mkInstructions "~/.claude/skills";
      force = true;
    };
  };

  home.file = extensionFiles;

  home.packages = [ pkgs.gemini-cli ];
}
