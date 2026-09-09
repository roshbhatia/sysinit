# The one set of facts behind the cloud-agent files: `.cursor/environment.json`
# and `hack/cloud-setup.sh`. Each of those is rendered
# from this by `flake/cloud-files.nix` and committed; `checks/cloud-files.nix`
# fails when the committed bytes drift from the render. Edit here, then run
# `hack/generate-cloud.sh`.
{ lib }:
let
  # "https://host/path" -> "host". The egress allowlist is derived from the
  # URLs the setup script contacts, so a new URL cannot miss the allowlist.
  hostOf = url: builtins.head (lib.splitString "/" (lib.removePrefix "https://" url));

  cachix = {
    url = "https://roshbhatia.cachix.org";
    publicKey = "roshbhatia.cachix.org-1:K7Kq2esJYhrV/aCH8Xl7h54y8NULg/k+7WkObNT9VDk=";
  };
  nixosCache.url = "https://cache.nixos.org";

  installer = {
    url = "https://install.determinate.systems/nix";
    # --init none: do not manage an init system. sandbox off for unprivileged
    # build daemons. The substituter and key flags are appended by the script
    # from `cachix` and `nixosCache`, so they are not repeated here.
    flags = [
      "--init"
      "none"
      "--no-confirm"
      "--extra-conf"
      "sandbox = false"
    ];
  };

  # Hosts the installer and nix reach that the script never names: the
  # installer downloads the Nix tarball from releases.nixos.org, and the flake
  # registry lives on channels.nixos.org. github.com is in Cursor's default set.
  egressImplicit = [
    "channels.nixos.org"
    "releases.nixos.org"
  ];

  scriptUrls = [
    installer.url
    cachix.url
    nixosCache.url
  ];
in
{
  inherit
    cachix
    nixosCache
    installer
    hostOf
    scriptUrls
    ;

  substituters = [
    cachix.url
    nixosCache.url
  ];

  flakeRef = "github:roshbhatia/sysinit#packages.x86_64-linux.cloudTools";
  binDir = "/usr/local/bin";
  setupScript = "hack/cloud-setup.sh";

  egressAllowlist = map hostOf scriptUrls ++ egressImplicit;

  cursor = {
    name = "sysinit-cloud-tools";
    egressMode = "default_with_network_settings";
  };
}
