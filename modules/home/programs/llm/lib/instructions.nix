let
  subagents = import ../subagents;

  formatSkillsBlock =
    skills:
    let
      firstSentence =
        s:
        let
          parts = builtins.split "\\." s;
          chunks = builtins.filter builtins.isString parts;
          first = if chunks == [ ] then s else builtins.head chunks;
        in
        first;
      entries = builtins.attrValues (
        builtins.mapAttrs (name: desc: "- `${name}` · ${firstSentence desc}") skills
      );
    in
    if entries == [ ] then "(no skills registered)" else builtins.concatStringsSep "\n" entries;

  makeInstructions =
    {
      localSkillDescriptions,
      skillsRoot ? "~/.claude/skills",
      openspecVersion ? "1.3.0",
    }:
    let
      skillsList = formatSkillsBlock localSkillDescriptions;

      sections = {
        stack = ''
          ## Stack

          - nix-darwin + home-manager + nix flakes (Apple Silicon, NixOS)
          - openspec ${openspecVersion} via `overlays/openspec.nix` (custom schema: `rosh-spec-driven`)
          - Agent tooling: claude-code, codex, gemini, cursor, aider — all configured from `modules/home/programs/llm/`
          - Shell: zsh; scripts in `hack/` are bash with `set -euo pipefail`, formatted by `shfmt -i 2 -ci -sr -s`
          - Formatter: `nixfmt-rfc-style` via `nix fmt`
        '';

        commands = ''
          ## Commands

          ```bash
          nix flake check          # validate flake (run before commits)
          nh os build              # build current host config (no system change)
          nh os switch             # apply config to system (use deliberately)
          nix fmt                  # format all Nix files
          task fmt:sh              # format hack/ shell scripts
          task fmt:sh:check        # verify shell formatting only
          task openspec:sync       # detect drift in openspec skills + forked schema
          openspec list --json     # list active OpenSpec changes
          openspec status --change "<name>" --json
          openspec instructions <artifact> --change "<name>" --json
          openspec validate "<name>"
          openspec schema validate rosh-spec-driven
          ```
        '';

        conventions = ''
          ## Conventions

          - Conventional commits, title-only, no body
          - One concern per commit; no formatting-only mixed with behavioral changes
          - Read context files (`AGENTS.md`, `openspec/`, `.sysinit/lessons.md`) before authoring
          - Modify existing files; avoid creating new ones unless required
          - Skills are the source of truth for domain rules; consult them via `${skillsRoot}/`
          - For OpenSpec work: schema is `rosh-spec-driven`; see `openspec/schemas/rosh-spec-driven/CHANGES.md`
          - On unexpected errors: stop, preserve evidence, fix root cause (no `--no-verify`)
          - Use `nix-shell` / `nix develop` for dependencies; avoid global installers
          - Prefer subagents (Explore, librarian, oracle) for parallel exploration; merge before coding
        '';

        skills = ''
          ## Skills

          Skills live at `${skillsRoot}/<name>/SKILL.md`, generated from `modules/home/programs/llm/skills/default.nix`.

          ${skillsList}
        '';

        prohibitions = ''
          ## Prohibitions

          - Never push to main
          - Never commit unless directed; stage and propose a message instead
          - Never use `--no-verify`, `--no-gpg-sign`, or other hook-bypass flags
          - Never use `any` or type suppressions without explicit permission
          - Never add emojis to code or generated files
          - Never run destructive git commands (`reset --hard`, `clean -f`, `branch -D`, force-push) without explicit instruction
          - Never edit hand-managed configuration when a Nix-managed equivalent exists
          - Never auto-update vendored upstream content; let the sync scripts surface drift
        '';

        context = ''
          ## Context

          - `.sysinit/` is gitignored scratch space for lessons and PRD notes; check `.sysinit/lessons.md` at session start
          - OpenSpec artifacts live at `openspec/changes/<name>/`; the active schema is `rosh-spec-driven`
          - User-level `~/.config/git/ignore` already excludes `**/.claude/`, `**/.agents/`, `**/openspec/` — do not duplicate in per-project `.gitignore`
        '';
      };

      order = [
        "stack"
        "commands"
        "conventions"
        "skills"
        "prohibitions"
        "context"
      ];

      rendered = builtins.concatStringsSep "\n" (map (key: sections.${key}) order);

      lineCount =
        let
          parts = builtins.split "\n" rendered;
          stringParts = builtins.filter builtins.isString parts;
        in
        builtins.length stringParts;

      maxLines = 200;
    in
    if lineCount > maxLines then
      throw "instructions.nix: rendered context exceeds ${toString maxLines} lines (got ${toString lineCount}). Trim sections or split per-agent extensions."
    else
      rendered;
in
{
  inherit makeInstructions;
  inherit subagents;
  inherit (subagents) formatSubagentAsMarkdown;
}
