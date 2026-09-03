{ lib }:
let
  vocab = import ../lib/vocab.nix { inherit lib; };
  frontmatter = import ../lib/frontmatter.nix { inherit lib; };
in
{
  code-reviewer = import ./code-reviewer.nix;
  implementor = import ./implementor.nix;
  librarian = import ./librarian.nix;
  oracle = import ./oracle.nix;

  formatSubagentAsMarkdown =
    {
      name,
      config,
      harness,
    }:
    let
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

      tools =
        if enabledTools == [ ] then
          null
        else if harness == "claude" then
          if claudeTools == [ ] then null else builtins.concatStringsSep ", " claudeTools
        else
          lib.genAttrs enabledTools (_name: true) // lib.genAttrs disabledTools (_name: false);

      metadata = {
        inherit name tools;
        description = config.description or "";
        model = if config ? model then resolveModel config.model else null;
        temperature = if config ? temperature && harness == "opencode" then config.temperature else null;
        thinking = config.thinking or null;
        extensions = config.extensions or null;
        skill = config.skill or null;
        output = config.output or null;
        defaultReads = config.defaultReads or null;
        defaultProgress = config.defaultProgress or null;
      };

      renderListSection =
        title: items:
        lib.optionalString (items != null && items != [ ]) ''
          ## ${title}

          ${lib.concatMapStringsSep "\n" (item: "- ${item}") items}
        '';

      sections = builtins.filter (section: section != "") [
        (config.description or "")
        (renderListSection "Use When" (config.useWhen or null))
        (renderListSection "Avoid When" (config.avoidWhen or null))
        (config.body or "")
        ''
          ## Dependency Setup

          - When dependencies are required, prefer a project-provided nix shell first (`nix-shell` or `nix develop`).
          - Use ad-hoc or global installers only when no project nix shell/dev shell exists.
        ''
      ];
    in
    vocab.applyVocab harness ''
      ${frontmatter.render metadata}
      ${builtins.concatStringsSep "\n\n" sections}
    '';
}
