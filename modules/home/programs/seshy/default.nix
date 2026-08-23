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

  # Filtered, not checked: openspec rejects the whole argument on one unknown
  # name, so a stray registry entry would fail every new session's postCreate.
  openspecTools = lib.intersectLists supportedTools declaredTools;

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
