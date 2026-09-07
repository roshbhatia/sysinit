{ lib, pkgs, ... }:
let
  askProviderNames = builtins.attrNames pkgs.ask-providers.providers;
  yamlFormat = pkgs.formats.yaml { };
in
{
  home.packages = [
    pkgs.sysinit-utils
    pkgs.ask
    (lib.lowPrio pkgs.ask-providers)
    pkgs.calldiff
  ];

  xdg.configFile =
    builtins.listToAttrs (
      map (name: {
        name = "ask/providers/${name}/provider.yaml";
        value.source = "${pkgs.ask-providers}/share/ask/providers/${name}/provider.yaml";
      }) askProviderNames
    )
    // {
      "ask/config.yaml".source = yamlFormat.generate "ask-config.yaml" {
        version = "ask.config/v1";
        provider.default = "claude";
      };

      # The cheap reader that read-guard and bash-guard name when they deny a
      # whole-file read over 16 KiB. It is Spotify's bulk-read mode as an ask
      # template: the file goes to a light model, bullets come back, and the
      # file never enters the caller's context. The invocation the deny prints
      # is `ask -p claude -m haiku -t bulk-read`; once ask carries a
      # per-provider light model the template alone will select it.
      "ask/templates/schemas/bulk-read-result.yaml".source =
        yamlFormat.generate "ask-schema-bulk-read-result.yaml" {
          version = "ask.schema/v1";
          name = "bulk-read-result";
          description = "What a bulk read returns: bullets and what it could not settle";
          schema = {
            type = "object";
            additionalProperties = false;
            required = [ "bullets" ];
            properties = {
              bullets = {
                type = "array";
                items.type = "string";
                description = "One fact each. Leads with a file:line or a symbol name.";
              };
              unresolved = {
                type = "array";
                items.type = "string";
                description = "What the question asked that the text does not answer.";
              };
            };
          };
        };

      "ask/templates/prompts/bulk-read.yaml".source = yamlFormat.generate "ask-prompt-bulk-read.yaml" {
        version = "ask.prompt/v2";
        name = "bulk-read";
        description = "Read a file on stdin for a coding agent that will not read it";
        schema = "bulk-read-result";
        variables = [
          {
            name = "question";
            type = "string";
            default = "";
            description = "What the caller needs from the file. Empty means its shape.";
          }
        ];
        prompt = ''
          The text on stdin is a file a coding agent will not read itself. Extract, do
          not interpret. Answer with bullets only. Each bullet leads with a line
          number or a symbol name so the agent can Read that range. No greeting, no
          preamble, no advice, no summary paragraph.
          {{if .question}}
          The agent needs: {{.question}}
          {{else}}
          The agent needs the shape of the file: what it declares, in order, with the
          line each declaration starts on.
          {{end}}
        '';
      };
    };
}
