{
  librarian = import ./librarian.nix;
  oracle = import ./oracle.nix;
  nixFlakeOperator = import ./nix-flake-operator.nix;
  luaConfigSpecialist = import ./lua-config-specialist.nix;
  valuesSchemaManager = import ./values-schema-manager.nix;
  buildValidator = import ./build-validator.nix;

  formatSubagentAsMarkdown =
    { name, config }:
    let
      inherit name;

      toolsLines =
        if config.tools == null || config.tools == { } then
          [ ]
        else
          builtins.map (k: "  ${k}: ${if config.tools.${k} then "true" else "false"}") (
            builtins.attrNames config.tools
          );
      toolsSection =
        if toolsLines == [ ] then "" else "tools:\n" + (builtins.concatStringsSep "\n" toolsLines);

      descriptionSection = [ (config.description or "") ];
      useWhenSection =
        if config.useWhen or null != null then
          [
            "\n## Use When:"
            (builtins.concatStringsSep "\n" (map (item: "- ${item}") config.useWhen))
          ]
        else
          [ ];
      avoidWhenSection =
        if config.avoidWhen or null != null then
          [
            "\n## Avoid When:"
            (builtins.concatStringsSep "\n" (map (item: "- ${item}") config.avoidWhen))
          ]
        else
          [ ];
      prompt = builtins.concatStringsSep "\n" (
        builtins.filter (s: s != "") (descriptionSection ++ useWhenSection ++ avoidWhenSection)
      );

      frontmatterLines = [
        "name: ${name}"
        "description: ${config.description or ""}"
        "mode: subagent"
        "temperature: ${toString (config.temperature or 0.1)}"
      ]
      ++ (if toolsSection != "" then [ toolsSection ] else [ ]);
      frontmatter = builtins.concatStringsSep "\n" frontmatterLines;
    in
    ''
      ---
      ${frontmatter}
      ---

      ${prompt}
    '';
}
