{
  config,
  lib,
  pkgs,
  ...
}:
let
  registry = import ../llm/harnesses/registry.nix;

  supportedTools = [
    "amazon-q"
    "antigravity"
    "auggie"
    "bob"
    "claude"
    "cline"
    "codebuddy"
    "codex"
    "continue"
    "costrict"
    "crush"
    "cursor"
    "factory"
    "forgecode"
    "gemini"
    "github-copilot"
    "iflow"
    "junie"
    "kilocode"
    "kimi"
    "kiro"
    "lingma"
    "oh-my-pi"
    "opencode"
    "pi"
    "qoder"
    "qwen"
    "roocode"
    "trae"
    "vibe"
    "windsurf"
  ];

  declaredTools = lib.naturalSort (
    lib.unique (lib.concatMap (h: h.openspecTool) (lib.attrValues registry))
  );

  unknownTools = lib.subtractLists supportedTools declaredTools;

  openspecTools =
    if unknownTools != [ ] then
      throw "seshy/default.nix: registry openspecTool names ${lib.concatStringsSep ", " unknownTools}, which `openspec init --tools` does not accept. openspec rejects the whole argument on one unknown name, so every new session would fail its postCreate hook."
    else
      declaredTools;

  settings = {
    branchFormat = "dev/{{.User}}/{{.Session}}/{{.Repo}}";
    sessionsDir = config.sysinit.paths.resolved.seshySessions;
    hooks = {
      postCreate = [
        "[ -d openspec ] || openspec init --tools ${lib.concatStringsSep "," openspecTools}"
        "command -v specutil >/dev/null 2>&1 && [ -d openspec/changes ] && specutil graph --as mermaid | mermaid-ascii || true"
      ];
      preDelete = [ ];
    };
  };
in
{
  xdg.configFile."seshy/config.yaml".source =
    (pkgs.formats.yaml { }).generate "seshy-config.yaml"
      settings;
}
