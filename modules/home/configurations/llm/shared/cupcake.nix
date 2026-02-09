{
  pkgs,
  ...
}:
let
  # Global Cupcake policies that work across all agents
  cupcakePolicyBase = ./cupcake/policies;

  # Rulebook for each harness
  makeRulebook =
    harness:
    pkgs.writeText "rulebook-${harness}.yml" ''
      version: "1.0"
      harness: ${harness}

      policies:
        directory: ${cupcakePolicyBase}/${harness}

      signals:
        git:
          enabled: true
        filesystem:
          enabled: true
    '';
in
{
  xdg.configFile = {
    # Global cupcake configuration
    "cupcake/rulebook.yml".source = makeRulebook "opencode";

    # OpenCode policies
    "cupcake/policies/opencode/system_protection.rego".source =
      ./cupcake/policies/opencode/system_protection.rego;
    "cupcake/policies/opencode/git_workflow.rego".source =
      ./cupcake/policies/opencode/git_workflow.rego;
    "cupcake/policies/opencode/file_protection.rego".source =
      ./cupcake/policies/opencode/file_protection.rego;
    "cupcake/policies/opencode/nix_workflow.rego".source =
      ./cupcake/policies/opencode/nix_workflow.rego;

    # Future: Claude Code policies would go here
    # "cupcake/policies/claude/..."

    # Future: Cursor policies would go here
    # "cupcake/policies/cursor/..."

    # Future: Factory AI policies would go here
    # "cupcake/policies/factory/..."
  };

  # Make cupcake-cli available globally
  home.packages = [ pkgs.cupcake-cli ];
}
