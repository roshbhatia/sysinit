{ personal, remoteBuild }:

let
  roseprime = {
    scheme = "roseprime";
    author = "casedami (neomodern.nvim), mapped to base16 slots";
    base00 = "141517";
    base01 = "1C1D1F";
    base02 = "27282A";
    base03 = "666068";
    base04 = "958B96";
    base05 = "C4B6C5";
    base06 = "D6CCD6";
    base07 = "E9E3E9";
    base08 = "C4959C";
    base09 = "C9AA95";
    base0A = "C9BF95";
    base0B = "9BBDB8";
    base0C = "9EB8C8";
    base0D = "96AFF2";
    base0E = "B29ECB";
    base0F = "9D777D";
  };

in
(personal.linuxWorkstation ./hardware.nix {
  k3s.enable = true;
  theme = {
    base16Scheme = roseprime;
    font.monospace = "WumpusMono Nerd Font Mono";
  };
})
// {
  extraModules = [ remoteBuild ];
}
