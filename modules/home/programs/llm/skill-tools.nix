{
  config,
  lib,
  pkgs,
  ...
}:
let
  askProviderNames = builtins.attrNames pkgs.ask-providers.providers;
  yamlFormat = pkgs.formats.yaml { };
  bulkRead = import ./bulk-read.nix;
in
{
  options.sysinit.ask.settings = lib.mkOption {
    inherit (yamlFormat) type;
    default = { };
    description = "Ask CLI settings, including independent generation and evaluation providers.";
  };

  options.sysinit.ask.rubrics = lib.mkOption {
    type = lib.types.attrsOf yamlFormat.type;
    default = { };
    description = "Named Ask evaluation question maps installed as reusable rubrics.";
  };

  config = {
    sysinit.ask.rubrics = lib.mapAttrs (_: lib.mkDefault) (import ./evaluation-rubrics.nix);
    sysinit.ask.settings = {
      version = lib.mkDefault "ask.config/v1";
      provider.default = lib.mkDefault "claude";
      evaluation = {
        provider = lib.mkDefault "cursor";
        model = lib.mkDefault "light";
      };
    };

    home.packages = [
      pkgs.sysinit-utils
      pkgs.citelock
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
      // lib.mapAttrs' (
        name: questions:
        lib.nameValuePair "ask/templates/rubrics/${name}.yaml" {
          source = yamlFormat.generate "ask-rubric-${name}.yaml" {
            version = "ask.rubric/v1";
            inherit name questions;
          };
        }
      ) config.sysinit.ask.rubrics
      // {
        "ask/config.yaml".source = yamlFormat.generate "ask-config.yaml" config.sysinit.ask.settings;

        # The cheap reader that read-router and bash-guard name when they deny a
        # whole-file read over 16 KiB. It is Spotify's bulk-read mode as an ask
        # template: the file goes to a light model, bullets come back, and the
        # file never enters the caller's context. The template pins the provider
        # and the light role, so the deny prints `ask -t bulk-read`.
        "ask/templates/schemas/${bulkRead.schema}.yaml".source =
          yamlFormat.generate "ask-schema-bulk-read-result.yaml"
            {
              version = "ask.schema/v1";
              name = bulkRead.schema;
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

        "ask/templates/prompts/${bulkRead.name}.yaml".source =
          yamlFormat.generate "ask-prompt-bulk-read.yaml"
            {
              version = "ask.prompt/v2";
              inherit (bulkRead)
                name
                schema
                provider
                model
                ;
              description = "Read a file on stdin for a coding agent that will not read it";
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
  };
}
