{ pkgs, ... }:

{
  imports = [ ../shared/stylix.nix ];

  stylix.image = pkgs.fetchurl {
    url = "https://wallpapercave.com/wp/wp12329549.png";
    sha256 = "sha256-9R3cDgd1VslCF6mG6jBO64MEdRjCGzWE4m/dAjEixzk=";
  };

  fonts.packages = [
    pkgs.ibm-plex
    pkgs.bookerly
  ];
}
