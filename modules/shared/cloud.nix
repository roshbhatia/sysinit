{ lib }:
let

  hostOf = url: builtins.head (lib.splitString "/" (lib.removePrefix "https://" url));

  cachix = {
    url = "https://roshbhatia.cachix.org";
    publicKey = "roshbhatia.cachix.org-1:K7Kq2esJYhrV/aCH8Xl7h54y8NULg/k+7WkObNT9VDk=";
  };
  nixosCache.url = "https://cache.nixos.org";

  installer = {
    url = "https://install.determinate.systems/nix";

    flags = [
      "--init"
      "none"
      "--no-confirm"
      "--extra-conf"
      "sandbox = false"
    ];
  };

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
