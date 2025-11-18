{
  general = ''
    # Best Practices and Enforced Guidelines

    The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
    "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
    interpreted as described in RFC 2119.

    ## General Rules

    1. **Scope Awareness**: Fully understand the project and tech stack before executing.
    2. **Proactive Error Handling**: Fix errors preemptively and clarify stack assumptions.
    3. **Context Utilization**: Read relevant context files and project documentation.
    4. **Commenting Standards**:
       - Start code with a path/filename comment.
       - Include comments that explain the purpose of the code, not just its effects.
    5. **Coding Principles**: Emphasize modularity, DRY principles, performance, and security.
    6. **Task Prioritization**: Complete one file before starting on another.
    7. **Handling Unfinished Work**: Use TODO comments for unfinished sections and confirm before proceeding.
    8. **Precision in Editing**: Deliver fully refined, complete files; methodically handle code changes.
    9. **Symbol Editing Focus**: Return only the modified symbol's definition in your edits.

    ## Verbosity Levels

    | Level | Description |
    |-------|-------------|
    | V=0   | Code golf (ultra-condensed) |
    | V=1   | Concise |
    | V=2   | Simple |
    | V=3   | Verbose, DRY with extracted functions |

    When V=3, extract common functionality into shared modules/files for reusability.

    ## Communication Style
    - Be concise in your output; avoid unnecessary verbosity
    - Get straight to the point with actionable information
    - Use clear, direct language

    ## Development Principles
    - Prefer Test-Driven Development (TDD) when implementing new features
    - Write tests first, then implement functionality
    - Always use existing patterns and conventions found in the codebase
    - Maintain consistency with established architecture and style

    ## When Uncertain
    - Ask clarifying questions rather than making assumptions
    - Elicit requirements when implementation details are ambiguous
    - Request examples or additional context when patterns are unclear
    - Confirm understanding before proceeding with significant changes

    ## Memory Management
    - Use memory tools to persist important project context and decisions
    - Reference existing memory entries for project-specific patterns and conventions
    - Update memory when discovering new patterns or making architectural decisions
    - Document non-obvious implementation details for future reference

    ## MCP Servers
    - Utilize the available MCP servers for enhanced capabilities
    - Leverage specialized servers for domain-specific tasks (AWS, Terraform, EKS, etc.)
    - Use the ast-grep MCP server for structural code analysis and refactoring

    ## Code Analysis
    - When querying code, prefer ast-grep for AST-based pattern matching
    - Use ast-grep for language-agnostic code search and transformations
    - Leverage semantic code search over simple text matching when possible

    ## Tool Usage with Nix
    - Before using external tools, check availability via `nix-shell -p <package>`
    - Use `nix search nixpkgs <query>` to discover available packages
    - Prefer running tools in isolated nix-shell environments for reproducibility
    - Example: `nix-shell -p jq --run "jq '.field' file.json"`

    ## Development Workflow
    - Use nix flakes for project dependencies when applicable
    - Leverage direnv for automatic environment activation
    - Test commands in nix-shell before committing to scripts
  '';
}
