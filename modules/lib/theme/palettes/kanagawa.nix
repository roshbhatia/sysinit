{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in
{
  meta = {
    name = "Kanagawa";
    id = "kanagawa";
    variants = [
      "wave"
      "dragon"
    ];
    supports = [ "dark" ];
    author = "rebelot";
    homepage = "https://github.com/rebelot/kanagawa.nvim";
  };

  palettes = {
    wave = utils.validatePalette {

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

      base = "#1f1f28";
      bg = "#1f1f28";
      bg_alt = "#16161d";
      surface = "#2a2a37";
      surface_alt = "#363646";
      text = "#dcd7ba";
      fg = "#dcd7ba";
      fg_alt = "#c8c093";
      comment = "#727169";
      blue = "#7e9cd8";
      cyan = "#7fb4ca";
      teal = "#6a9589";
      green = "#98bb6c";
      yellow = "#e6c384";
      orange = "#ffa066";
      red = "#c34043";
      purple = "#957fb8";
      accent = "#7e9cd8";
      accent_dim = "#2a2a37";
    };

    dragon = utils.validatePalette {

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

      base = "#181616";
      bg = "#181616";
      bg_alt = "#12120f";
      surface = "#1d1c19";
      surface_alt = "#282727";
      text = "#c5c9c5";
      fg = "#c5c9c5";
      fg_alt = "#a6a69c";
      comment = "#7a8382";
      blue = "#8ba4b0";
      cyan = "#8ea4a2";
      teal = "#949fb5";
      green = "#87a987";
      yellow = "#c4b28a";
      orange = "#b6927b";
      red = "#c4746e";
      purple = "#8992a7";
      accent = "#8ba4b0";
      accent_dim = "#1d1c19";
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;

  appAdapters = {
    wezterm = {
      wave = "Kanagawa (Gogh)";
      dragon = "Kanagawa Dragon (Gogh)";
    };

    neovim = {
      plugin = "rebelot/kanagawa.nvim";
      name = "kanagawa";
      setup = "kanagawa";
      colorscheme = variant: "kanagawa-${variant}";
    };

    bat = variant: "kanagawa-${variant}";
    delta = variant: "kanagawa-${variant}";
    atuin = variant: "kanagawa-${variant}";
    vivid = variant: "kanagawa-${variant}";
    helix = _variant: "kanagawa";
    nushell = variant: "kanagawa-${variant}.nu";
    k9s = variant: "kanagawa-${variant}";
  };
}
