{
  lib,
  ...
}:
let
  litellm = import ../shared/litellm.nix;

  config = {
    model_list = [
      {
        model_name = "github_copilot/gpt-4";
        litellm_params = {
          model = "github_copilot/gpt-4";
        };
      }
    ];
    general_settings = {
      master_key = litellm.masterKey;
    };
  };

  yaml = lib.generators.toYAML { } config;
in
{
  xdg.configFile."litellm/config.yaml" = {
    text = yaml;
    force = true;
  };
}

