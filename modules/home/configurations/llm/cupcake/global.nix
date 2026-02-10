{
  pkgs,
  lib,
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
    "cupcake/rulebook.yml" = {
      source = makeRulebook "opencode";
      force = true;
    };

    "cupcake/policies/opencode/system_protection.rego" = {
      source = ./cupcake/policies/opencode/system_protection.rego;
      force = true;
    };
    "cupcake/policies/opencode/git_workflow.rego" = {
      source = ./cupcake/policies/opencode/git_workflow.rego;
      force = true;
    };
    "cupcake/policies/opencode/file_protection.rego" = {
      source = ./cupcake/policies/opencode/file_protection.rego;
      force = true;
    };
    "cupcake/policies/opencode/nix_workflow.rego" = {
      source = ./cupcake/policies/opencode/nix_workflow.rego;
      force = true;
    };
  };

  home.activation.cupcakeInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.cupcake-cli}/bin/cupcake init --global --harness opencode
  '';
}
