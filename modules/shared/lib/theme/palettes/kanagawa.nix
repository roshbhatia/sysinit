{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

rec {
  meta = {
    name = "Kanagawa";
    id = "kanagawa";
    variants = [
      "lotus"
      "wave"
      "dragon"
    ];
    supports = [
      "light"
      "dark"
    ];
    appearanceMapping = {
      light = "lotus";
      dark = "wave";
    };
    author = "rebelot";
    homepage = "https://github.com/rebelot/kanagawa.nvim";
  };

  palettes = {
    lotus = utils.validatePalette (rec {
      lotusWhite0 = "#d5cea3";
      lotusWhite1 = "#dcd5ac";
      lotusWhite2 = "#e5ddb0";
      lotusWhite3 = "#f2ecbc";
      lotusWhite4 = "#e7dba0";
      lotusWhite5 = "#e4d794";

      oldWhite = "#545464";
      fujiWhite = "#545464";
      fujiGray = "#a6a69c";

      lotusGray = "#716e61";
      lotusGray2 = "#8a8980";
      lotusGray3 = "#b1b1a7";

      lotusViolet1 = "#a09cac";
      lotusViolet2 = "#766b90";
      lotusViolet3 = "#c9cbd1";
      lotusViolet4 = "#624c83";

      lotusBlue1 = "#c7d7e0";
      lotusBlue2 = "#b5cbd2";
      lotusBlue3 = "#9fb5c9";
      lotusBlue4 = "#4d699b";
      lotusBlue5 = "#5d57a3";

      lotusGreen = "#6f894e";
      lotusGreen2 = "#6e915f";
      lotusGreen3 = "#b7d0ae";

      lotusYellow = "#77713f";
      lotusYellow2 = "#836f4a";
      lotusYellow3 = "#dca561";
      lotusYellow4 = "#c8ae6d";

      lotusOrange = "#cc6d00";
      lotusOrange2 = "#e98a00";

      lotusPink = "#b35b79";
      lotusRed = "#c84053";
      lotusRed2 = "#d7474b";
      lotusRed3 = "#e82424";
      lotusRed4 = "#d9a594";

      lotusCyan = "#597b75";
      lotusTeal1 = "#4e8ca2";
      lotusTeal2 = "#5e857a";
      lotusTeal3 = "#6693bf";

      base = lotusWhite3;
      bg = lotusWhite3;
      bg_alt = lotusWhite2;
      surface = lotusWhite1;
      surface_alt = lotusWhite0;
      text = fujiWhite;
      fg = fujiWhite;
      fg_alt = lotusGray;
      comment = lotusGray2;
      blue = lotusBlue4;
      cyan = lotusCyan;
      teal = lotusTeal2;
      green = lotusGreen;
      yellow = lotusYellow4;
      orange = lotusOrange;
      red = lotusRed;
      purple = lotusViolet4;
      accent = lotusBlue4;
      accent_dim = lotusWhite1;
    });

    wave = utils.validatePalette (rec {
      sumiInk0 = "#16161d";
      sumiInk1 = "#1f1f28";
      sumiInk2 = "#2a2a37";
      sumiInk3 = "#363646";
      sumiInk4 = "#54546d";

      oldWhite = "#c8c093";
      fujiWhite = "#dcd7ba";
      fujiGray = "#727169";

      waveBlue1 = "#223249";
      waveBlue2 = "#2d4f67";
      waveAqua1 = "#6a9589";
      waveAqua2 = "#7aa89f";

      winterGreen = "#2b3328";
      winterYellow = "#49443c";
      winterRed = "#43242b";
      winterBlue = "#252535";

      autumnGreen = "#76946a";
      autumnRed = "#c34043";
      autumnYellow = "#dca561";

      samuraiRed = "#e82424";
      roninYellow = "#ff9e3b";
      dragonBlue = "#658594";

      crystalBlue = "#7e9cd8";
      springViolet1 = "#938aa9";
      springViolet2 = "#9cabca";
      springBlue = "#7fb4ca";
      springGreen = "#98bb6c";
      boatYellow2 = "#c0a36e";
      carpYellow = "#e6c384";
      sakuraPink = "#d27e99";
      waveRed = "#e46876";
      peachRed = "#ff5d62";
      surimiOrange = "#ffa066";
      oniViolet = "#957fb8";

      base = sumiInk1;
      bg = sumiInk1;
      bg_alt = sumiInk0;
      surface = sumiInk2;
      surface_alt = sumiInk3;
      text = fujiWhite;
      fg = fujiWhite;
      fg_alt = oldWhite;
      comment = fujiGray;
      blue = crystalBlue;
      cyan = springBlue;
      teal = waveAqua1;
      green = springGreen;
      yellow = carpYellow;
      orange = surimiOrange;
      red = autumnRed;
      purple = oniViolet;
      accent = crystalBlue;
      accent_dim = sumiInk2;
    });

    dragon = utils.validatePalette (rec {
      dragonBlack0 = "#0d0c0c";
      dragonBlack1 = "#12120f";
      dragonBlack2 = "#1d1c19";
      dragonBlack3 = "#181616";
      dragonBlack4 = "#282727";
      dragonBlack5 = "#393836";
      dragonBlack6 = "#625e5a";

      dragonWhite = "#c5c9c5";
      dragonGreen = "#87a987";
      dragonGreen2 = "#8a9a7b";
      dragonPink = "#a292a3";
      dragonOrange = "#b6927b";
      dragonOrange2 = "#b98d7b";
      dragonGray = "#a6a69c";
      dragonGray2 = "#9e9b93";
      dragonGray3 = "#7a8382";
      dragonBlue = "#8ba4b0";
      dragonBlue2 = "#8ea4a2";
      dragonViolet = "#8992a7";
      dragonRed = "#c4746e";
      dragonAqua = "#8ea4a2";
      dragonAsh = "#737c73";
      dragonTeal = "#949fb5";
      dragonYellow = "#c4b28a";

      base = dragonBlack3;
      bg = dragonBlack3;
      bg_alt = dragonBlack1;
      surface = dragonBlack2;
      surface_alt = dragonBlack4;
      text = dragonWhite;
      fg = dragonWhite;
      fg_alt = dragonGray;
      comment = dragonGray3;
      blue = dragonBlue;
      cyan = dragonAqua;
      teal = dragonTeal;
      green = dragonGreen;
      yellow = dragonYellow;
      orange = dragonOrange;
      red = dragonRed;
      purple = dragonViolet;
      accent = dragonBlue;
      accent_dim = dragonBlack2;
    });
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
