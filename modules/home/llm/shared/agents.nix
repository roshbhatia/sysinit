let
  subagents = import ./subagents;
in
{
  general = ''
    Keywords: MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, MAY, OPTIONAL. (RFC 2119)

    MUST be concise and clear in communication.
    MUST understand project scope and tech stack before execution.
    MUST fix errors proactively and clarify stack assumptions.
    MUST read context files and documentation.
    MUST start code with path/filename and include purpose comments.
    MUST apply modularity, DRY, performance, security principles.
    MUST finish one file before starting another.
    MUST use TODO for incomplete work and confirm before proceeding.
    MUST deliver refined, complete files; return only modified symbols.
    NEVER create ad-hoc documentaiton. You MAY create applicable documentation, but only that which a human would write.
    MUST use serena_get_symbols_overview first when exploring files.
    MUST use serena and astgrep over internal tools exploring files and editing files.
    NEVER use emojis in code.
  '';

  inherit subagents;
  inherit (subagents) formatSubagentAsMarkdown;
}
