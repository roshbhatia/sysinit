{
  ...
}:

final: prev: {
  nushell = prev.nushell.overrideAttrs (rec {
    version = "0.106.1";

    src = final.fetchFromGitHub {
      owner = "nushell";
      repo = "nushell";
      rev = version;
      hash = "sha256-VrGsdO7RiTlf8JK3MBMcgj0z4cWUklDwikMN5Pu6JQI=";
    };
  });
}

