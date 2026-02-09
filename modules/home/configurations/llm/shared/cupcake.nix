{
  pkgs,
  ...
}:
let
  cupcakePolicyBase = ./cupcake/policies;

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
    "cupcake/rulebook.yml".source = makeRulebook "opencode";

    "cupcake/policies/opencode/system_protection.rego".source =
      ./cupcake/policies/opencode/system_protection.rego;
    "cupcake/policies/opencode/git_workflow.rego".source =
      ./cupcake/policies/opencode/git_workflow.rego;
    "cupcake/policies/opencode/file_protection.rego".source =
      ./cupcake/policies/opencode/file_protection.rego;
    "cupcake/policies/opencode/nix_workflow.rego".source =
      ./cupcake/policies/opencode/nix_workflow.rego;
  };
}
