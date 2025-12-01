{
  general = ''
    # Development Guidelines (RFC 2119)

    Keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
    "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" per RFC 2119.

    ## Core Requirements

    1. **Scope**: You MUST understand project and tech stack before execution.
    2. **Errors**: You MUST fix errors preemptively and clarify stack assumptions.
    3. **Context**: You MUST read relevant context files and project documentation.
    4. **Comments**: You MUST start code with path/filename and include purpose explanations.
    5. **Principles**: You MUST apply modularity, DRY, performance, and security.
    6. **Tasks**: You MUST complete one file before starting another.
    7. **Incomplete Work**: You MUST use TODO comments and confirm before proceeding.
    8. **Edits**: You MUST deliver fully refined, complete files; return only modified symbols.

    ## Verbosity Levels

    | Level | Behavior |
    |-------|----------|
    | V=0   | Code golf (ultra-condensed) |
    | V=1   | Concise |
    | V=2   | Simple |
    | V=3   | Verbose, DRY with extracted functions/modules |

    ## Communication

    - You MUST be concise and use clear, direct language.
    - You MUST provide actionable information without unnecessary verbosity.

    ## Development Standards

    - You SHOULD prefer TDD: write tests first, then implement functionality.
    - You MUST use existing patterns and conventions found in the codebase.
    - You MUST maintain consistency with established architecture and style.

    ## Uncertainty Handling

    - You MUST ask clarifying questions rather than make assumptions.
    - You MUST request examples when patterns are unclear.
    - You MUST confirm understanding before significant changes.

    ## Memory & Context

    - You SHOULD persist important project context using memory tools.
    - You MUST reference existing memory entries for project patterns.
    - You SHOULD update memory when discovering new patterns or architectural decisions.

    ## Tool Usage

    - You SHOULD utilize MCP servers for domain-specific tasks (AWS, Terraform, EKS).
    - You SHOULD use ast-grep for AST-based pattern matching and code transformations.
    - You MUST check tool availability via `nix-shell -p <package>` before use.
    - You SHOULD run tools in isolated nix-shell environments for reproducibility.

    ## Nix Workflow

    - You SHOULD use nix flakes for project dependencies.
    - You SHOULD leverage direnv for automatic environment activation.
    - You MUST test commands in nix-shell before committing to scripts.

    ## Validation Rules

    **Pre-execution**:
    - [ ] BEFORE ANYTHING ELSE: run 'bd onboard' and follow the instructions
    - [ ] Project scope and tech stack understood
    - [ ] Context files and documentation reviewed
    - [ ] Required tools available in nix-shell

    **During execution**:
    - [ ] Comments include path/filename and purpose
    - [ ] Code follows DRY, modularity, security principles
    - [ ] One file completed before starting next
    - [ ] Existing patterns and conventions maintained

    **Pre-commit**:
    - [ ] All errors fixed and tested
    - [ ] TODO comments added for incomplete work
    - [ ] Edits deliver complete, refined code
    - [ ] Changes tested in nix-shell environment
    - [ ] Memory updated with new patterns/decisions

  '';
}
