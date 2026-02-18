{ pkgs, ... }:

{
  home.file = {
    ".local/bin/k".source = "${pkgs.kubecolor}/bin/kubecolor";
    ".local/bin/kubectl".source = "${pkgs.kubecolor}/bin/kubecolor";

    ".kube/kuberc".text = ''
      apiVersion: kubectl.config.k8s.io/v1beta1
      kind: Preference

      defaults:
        - command: delete
          options:
            - name: interactive
              default: "true"

      aliases:
        - name: getj
          command: get
          options:
            - name: output
              default: json

        - name: gety
          command: get
          options:
            - name: output
              default: yaml

        - name: getw
          command: get
          options:
            - name: output
              default: wide
    '';
  };
}
