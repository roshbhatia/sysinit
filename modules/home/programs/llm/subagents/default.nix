{
  code-reviewer = import ./code-reviewer.nix;
  implementor = import ./implementor.nix;
  librarian = import ./librarian.nix;
  oracle = import ./oracle.nix;

  formatSubagentAsMarkdown =
    { name, config }:
    let
      # tools is an attrset of name -> bool; emit only enabled ones as CSV
      enabledTools =
        if config ? tools && config.tools != { } then
          builtins.filter (k: config.tools.${k}) (builtins.attrNames config.tools)
        else
          [ ];
      toolsLines =
        if enabledTools == [ ] then
          [ ]
        else
          [ "tools:" ]
          ++ map (t: "  ${t}: true") enabledTools
          ++ map (t: "  ${t}: false") (
            builtins.filter (k: !config.tools.${k}) (builtins.attrNames config.tools)
          );

      frontmatterLines = builtins.filter (s: s != "") (
        [
          "name: ${name}"
          "description: ${config.description or ""}"
        ]
        ++ toolsLines
        ++ (if config ? model then [ "model: ${config.model}" ] else [ ])
        ++ (if config ? thinking then [ "thinking: ${config.thinking}" ] else [ ])
        ++ (if config ? extensions then [ "extensions: ${config.extensions}" ] else [ ])
        ++ (if config ? skill then [ "skill: ${config.skill}" ] else [ ])
        ++ (if config ? output then [ "output: ${config.output}" ] else [ ])
        ++ (if config ? defaultReads then [ "defaultReads: ${config.defaultReads}" ] else [ ])
        ++ (
          if config ? defaultProgress then
            [ "defaultProgress: ${if config.defaultProgress then "true" else "false"}" ]
          else
            [ ]
        )
      );
      frontmatter = builtins.concatStringsSep "\n" frontmatterLines;

      descriptionSection = [ (config.description or "") ];
      useWhenSection =
        if config ? useWhen && config.useWhen != null then
          [
            "\n## Use When:"
            (builtins.concatStringsSep "\n" (map (item: "- ${item}") config.useWhen))
          ]
        else
          [ ];
      avoidWhenSection =
        if config ? avoidWhen && config.avoidWhen != null then
          [
            "\n## Avoid When:"
            (builtins.concatStringsSep "\n" (map (item: "- ${item}") config.avoidWhen))
          ]
        else
          [ ];
      dependencySetupSection = [
        "\n## Dependency Setup:"
        "- When dependencies are required, prefer a project-provided nix shell first (`nix-shell` or `nix develop`)."
        "- Use ad-hoc or global installers only when no project nix shell/dev shell exists."
      ];
      prompt = builtins.concatStringsSep "\n" (
        builtins.filter (s: s != "") (
          descriptionSection ++ useWhenSection ++ avoidWhenSection ++ dependencySetupSection
        )
      );
    in
    ''
      ---
      ${frontmatter}
      ---

      ${prompt}
    '';
}
