{
  ...
}:

final: prev: {
  nushell = prev.nushell.overrideAttrs (rec {
    version = "0.106.1";
    src = final.fetchFromGitHub {
      owner = "nushell";
      repo = "nushell";
      tag = version;
      hash = "sha256-VrGsdO7RiTlf8JK3MBMcgj0z4cWUklDwikMN5Pu6JQI=";
    };
    cargoHash = "sha256-GSpR54QGiY9Yrs/A8neoKK6hMvSr3ORtNnwoz4GGprY=";
  });
}

