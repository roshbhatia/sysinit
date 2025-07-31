{
  lib,
  ...
}:
let
  litellm = import ../shared/litellm.nix;

  config = {
    model_list = [
      {
        model_name = litellm.model;
        litellm_params = {
          model = litellm.model;
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

