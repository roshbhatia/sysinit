{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  skillsLib = import ../skills.nix { inherit pkgs; };

  defaultInstructions = llmLib.instructions.makeInstructions {
    inherit (skillsLib) localSkillDescriptions;
    openspecVersion = pkgs.openspec.version;
    skillsRoot = "~/.claude/skills";
  };

  claudeHookScript = ''
    #!/usr/bin/env bash
    echo "=== AGENTS.md Files Found ==="
    find "$CLAUDE_PROJECT_DIR" -name "AGENTS.md" -type f | while read -r file; do
        echo "--- File: $file ---"
        cat "$file"
        echo ""
    done
  '';

  subagents = lib.filterAttrs (n: _: n != "formatSubagentAsMarkdown") llmLib.instructions.subagents;

  # Tier A: read-only commands that are safe to auto-allow without prompting.
  # Each entry is an exact-command form and a prefix form (with trailing space + `*`).
  # Patterns intentionally exclude commands with destructive flags (find -delete,
  # sed -i, awk -i inplace, git -C * commit, gh api POST/PUT/DELETE, etc.).
  tierAReadOnlyBash = [
    # git read-only
    "git status"
    "git status *"
    "git diff"
    "git diff *"
    "git log"
    "git log *"
    "git show"
    "git show *"
    "git blame *"
    "git ls-files"
    "git ls-files *"
    "git branch"
    "git branch --show-current"
    "git branch -v"
    "git branch --list *"
    "git remote -v"
    "git remote get-url *"
    "git rev-parse *"
    "git config --get *"
    "git config --list"
    "git config --list *"
    "git check-ignore -v *"
    "git tag"
    "git tag --list *"
    "git describe *"
    "git stash list"

    # openspec read-only
    "openspec list"
    "openspec list *"
    "openspec status"
    "openspec status *"
    "openspec instructions *"
    "openspec validate"
    "openspec validate *"
    "openspec show *"
    "openspec schemas"
    "openspec schema which"
    "openspec schema which *"
    "openspec schema validate"
    "openspec schema validate *"
    "openspec schema show *"
    "openspec config get *"
    "openspec config list"
    "openspec config list *"
    "openspec config path"
    "openspec templates *"
    "openspec --version"
    "openspec --help"

    # nix read-only
    "nix eval *"
    "nix flake check"
    "nix flake check *"
    "nix flake show"
    "nix flake show *"
    "nix flake metadata"
    "nix flake metadata *"
    "nix flake info"
    "nix flake info *"
    "nix flake lock --update-input *"
    "nix path-info *"
    "nix derivation show *"
    "nix log *"
    "nix hash *"
    "nix-prefetch-url *"
    "nix store prefetch-file *"
    "nix store ls *"
    "nix store path-from-hash-part *"

    # filesystem reads (commands with no destructive flags)
    "ls"
    "ls *"
    "pwd"
    "cat *"
    "head"
    "head *"
    "tail"
    "tail *"
    "wc"
    "wc *"
    "which *"
    "file *"
    "stat *"
    "du *"
    "tree"
    "tree *"
    "realpath *"
    "readlink *"
    "basename *"
    "dirname *"

    # search (read-only)
    "grep"
    "grep *"
    "rg"
    "rg *"

    # process / system reads
    "ps"
    "ps *"
    "lsof *"
    "whoami"
    "id"
    "hostname"
    "hostname -s"
    "uname"
    "uname *"
    "top -l 1"
    "top -l 1 *"
    "uptime"
    "date"
    "date *"
    "system_profiler *"
    "defaults read *"
    "sw_vers"
    "sysctl -n *"

    # GitHub (read-only)
    "gh pr list"
    "gh pr list *"
    "gh pr view"
    "gh pr view *"
    "gh pr diff *"
    "gh issue list"
    "gh issue list *"
    "gh issue view *"
    "gh repo view"
    "gh repo view *"
    "gh release list"
    "gh release list *"
    "gh release view *"
    "gh workflow list"
    "gh workflow view *"
    "gh run list"
    "gh run list *"
    "gh run view *"
    "gh auth status"
    "gh api GET *"
    "gh api -X GET *"

    # text utilities (no -i/-w modes)
    "echo *"
    "printf *"
    "sort"
    "sort *"
    "uniq"
    "uniq *"
    "cut *"
    "tr *"
    "rev"
    "rev *"
    "column *"
    "jq *"
    "yq *"

    # misc inspection
    "env"
    "type *"
    "command -v *"
    "shfmt -d *"
    "nixfmt --check *"
    "nixfmt-rfc-style --check *"

    # diff
    "diff *"
    "cmp *"
  ];

  bashAllowEntries = builtins.map (cmd: "Bash(${cmd})") tierAReadOnlyBash;
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    settings = {
      permissions = {
        allow = bashAllowEntries;
      };

      hooks = {
        SessionStart = [
          {
            matcher = "startup";
            hooks = [
              {
                type = "command";
                command = "${config.home.homeDirectory}/.claude/hooks/append_agentsmd_context";
              }
            ];
          }
        ];
      };
    };

    context = defaultInstructions;

    agents = lib.mapAttrs (
      name: agentConfig:
      llmLib.instructions.formatSubagentAsMarkdown {
        inherit name;
        config = agentConfig;
      }
    ) subagents;

  };

  home.file.".claude/hooks/append_agentsmd_context" = {
    text = claudeHookScript;
    executable = true;
  };
}
