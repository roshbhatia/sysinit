{ config, ... }:

{
  # https://kubernetes.io/docs/reference/kubectl/kuberc/
  home.file."${config.home.homeDirectory}/.kube/kuberc".text = ''
    apiVersion: kubectl.config.k8s.io/v1beta1
    kind: Preference

    # Suggested defaults from Kubernetes documentation
    defaults:
      # Default to server-side apply
      - command: apply
        options:
          - name: server-side
            default: "true"

      # Default to interactive deletion to prevent accidents
      - command: delete
        options:
          - name: interactive
            default: "true"

    # Useful aliases
    aliases:
      # Get with JSON output for structured data
      - name: getj
        command: get
        options:
          - name: output
            default: json

      # Get with YAML output
      - name: gety
        command: get
        options:
          - name: output
            default: yaml

      # Wide output for more details
      - name: getw
        command: get
        options:
          - name: output
            default: wide
  '';
}
