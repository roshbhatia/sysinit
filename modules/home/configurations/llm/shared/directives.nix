{
  general = ''
    # Development Guidelines

    Keywords: MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, MAY, OPTIONAL. (RFC 2119)

    Core Requirements:
    MUST understand project scope and tech stack before execution.
    MUST fix errors proactively and clarify stack assumptions.
    MUST read context files and documentation.
    MUST start code with path/filename and include purpose comments.
    MUST apply modularity, DRY, performance, security principles.
    MUST finish one file before starting another.
    MUST use TODO for incomplete work and confirm before proceeding.
    MUST deliver refined, complete files; return only modified symbols.
    NEVER create ad-hoc documentaiton. You MAY create applicable documentation, but only that which a human would write.
    NEVER use emojis in code.

    ## Communication
    MUST be concise and clear in communication.
    MUST provide actionable info without verbosity.
    MUST NEVER use emojis.

    ## Development Standards
    SHOULD prefer TDD (tests first).
    MUST follow existing patterns and conventions.
    MUST maintain architecture and style consistency.
    NEVER use emojis in code.

    ## Uncertainty Handling
    MUST ask clarifying questions instead of assuming.
    MUST request examples when patterns unclear.
    MUST confirm understanding before major changes.

    ## Memory & Context
    SHOULD persist important context using memory tools.
    MUST reference existing memory entries for patterns.
    SHOULD update memory with new patterns/decisions.

    ## Tool Usage
    MUST use serena_get_symbols_overview first when exploring files.
    MUST check tool availability via nix-shell -p <package> before use.
    SHOULD run tools in isolated nix-shell environments.

    ## Validation Rules
    ### Pre-execution
    MUST run bd onboard before anything else.
    MUST ensure tools available in nix-shell.

    ### During execution
    MUST include path/filename and purpose in comments.
    MUST follow DRY, modularity, security principles.
    MUST maintain existing patterns and conventions.
    It is RECOMMENDED to fix LSP diagnostics if available.

    ### Pre-commit
    MUST fix all errors and test before commit.
    MUST add TODO for incomplete work.
    MUST deliver complete, refined code.
    MUST test changes in nix-shell.
    MUST update memory with new patterns/decisions.
    ALWAYS remove emojis in code.
  '';
}
