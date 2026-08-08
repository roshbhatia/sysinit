{ lib }:
let
  vocab = import ../lib/vocab.nix { inherit lib; };
in
{
  code-reviewer = import ./code-reviewer.nix;
  implementor = import ./implementor.nix;
  librarian = import ./librarian.nix;
  oracle = import ./oracle.nix;

  # One definition renders to two harnesses with incompatible frontmatter.
  # OpenCode wants a map of its own lowercase tool names; Claude Code wants a
  # CSV of capitalized ones. Emitting the OpenCode form for both made the
  # Claude side name tools that do not exist, which resolves to an empty grant.
  formatSubagentAsMarkdown =
    {
      name,
      config,
      harness,
    }:
    let
      # OpenCode tool name -> Claude Code tool name. `list` and `patch` have no
      # Claude Code counterpart; dropping them is correct, because mapping them
      # onto Read/Edit would widen the grant past what the definition asked for.
      claudeToolNames = {
        bash = "Bash";
        edit = "Edit";
        glob = "Glob";
        grep = "Grep";
        read = "Read";
        skill = "Skill";
        webfetch = "WebFetch";
        write = "Write";
      };

      # Short alias -> the model ID each harness accepts. Claude Code takes the
      # alias verbatim; OpenCode validates against models.dev and needs the
      # provider prefix. Unlisted aliases fail the build instead of shipping an
      # ID a harness will reject at load time.
      modelIds = {
        claude = {
          haiku = "haiku";
          sonnet = "sonnet";
          opus = "opus";
        };
        opencode = {
          haiku = "anthropic/claude-haiku-4-5";
          sonnet = "anthropic/claude-sonnet-5";
        };
      };
      resolveModel =
        alias:
        let
          table = modelIds.${harness};
        in
        table.${alias} or (throw "Subagent ${name}: model alias '${alias}' has no ${harness} model ID");

      # tools is an attrset of name -> bool
      enabledTools =
        if config ? tools && config.tools != { } then
          builtins.filter (k: config.tools.${k}) (builtins.attrNames config.tools)
        else
          [ ];
      disabledTools =
        if config ? tools && config.tools != { } then
          builtins.filter (k: !config.tools.${k}) (builtins.attrNames config.tools)
        else
          [ ];

      claudeTools = map (t: claudeToolNames.${t}) (
        builtins.filter (t: claudeToolNames ? ${t}) enabledTools
      );

      toolsLines =
        if enabledTools == [ ] then
          [ ]
        else if harness == "claude" then
          if claudeTools == [ ] then [ ] else [ "tools: ${builtins.concatStringsSep ", " claudeTools}" ]
        else
          [ "tools:" ] ++ map (t: "  ${t}: true") enabledTools ++ map (t: "  ${t}: false") disabledTools;

      frontmatterLines = builtins.filter (s: s != "") (
        [
          "name: ${name}"
          "description: ${config.description or ""}"
        ]
        ++ toolsLines
        ++ (if config ? model then [ "model: ${resolveModel config.model}" ] else [ ])
        # OpenCode accepts temperature in agent frontmatter; Claude Code has no
        # such key, so the value stays out of the Claude tree.
        ++ (
          if config ? temperature && harness == "opencode" then
            [ "temperature: ${toString config.temperature}" ]
          else
            [ ]
        )
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
      bodySection = if config ? body && config.body != null then [ ("\n" + config.body) ] else [ ];
      dependencySetupSection = [
        "\n## Dependency Setup:"
        "- When dependencies are required, prefer a project-provided nix shell first (`nix-shell` or `nix develop`)."
        "- Use ad-hoc or global installers only when no project nix shell/dev shell exists."
      ];
      prompt = builtins.concatStringsSep "\n" (
        builtins.filter (s: s != "") (
          descriptionSection ++ useWhenSection ++ avoidWhenSection ++ bodySection ++ dependencySetupSection
        )
      );
    in
    vocab.applyVocab harness ''
      ---
      ${frontmatter}
      ---

      ${prompt}
    '';
}
