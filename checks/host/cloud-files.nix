{ pkgs, lib }:
let
  cloud = import ../../flake/cloud-files.nix { inherit pkgs lib; };
in
import ../lib/nushell.nix { inherit pkgs; } {
  name = "cloud-files";
  script = ./cloud-files.nu;
  arguments = [
    ../../hack/cloud-setup.sh
    "${cloud.all}/hack/cloud-setup.sh"
    cloud.setupScript
    cloud.environmentJson
    (cloud.facts.hostOf cloud.facts.installer.url)
  ];
}
