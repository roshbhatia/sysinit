{
  pkgs,
  ...
}:

let
  yamlFormat = pkgs.formats.yaml { };

  kuberc = {
    apiVersion = "kubectl.config.k8s.io/v1beta1";
    kind = "Preference";

    defaults = [
      {
        command = "delete";
        options = [
          {
            name = "interactive";
            default = "true";
          }
        ];
      }
    ];

    aliases = [
      {
        name = "getj";
        command = "get";
        options = [
          {
            name = "output";
            default = "json";
          }
        ];
      }
      {
        name = "gety";
        command = "get";
        options = [
          {
            name = "output";
            default = "yaml";
          }
        ];
      }
      {
        name = "getw";
        command = "get";
        options = [
          {
            name = "output";
            default = "wide";
          }
        ];
      }
    ];
  };
in
{
  home.file = {
    ".local/bin/k".source = "${pkgs.kubecolor}/bin/kubecolor";

    ".kube/kuberc".source = yamlFormat.generate "kuberc" kuberc;
  };
}
