{
  config,
  pkgs,
  ...
}:
let
  parserConfig = {
    parser-directories = [
      "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim"
      "${config.home.homeDirectory}/github"
      "${config.home.homeDirectory}/src"
      "${config.home.homeDirectory}/source"
      "${config.home.homeDirectory}/projects"
      "${config.home.homeDirectory}/dev"
      "${config.home.homeDirectory}/git"
      "${config.home.homeDirectory}/.local/share/nvim/lazy/nvim-treesitter/parser"
    ];
    theme = {
      attribute = {
        color = 124;
        italic = true;
      };
      comment = {
        color = 245;
        italic = true;
      };
      constant = 94;
      "constant.builtin" = {
        bold = true;
        color = 94;
      };
      constructor = 136;
      embedded = null;
      function = 26;
      "function.builtin" = {
        bold = true;
        color = 26;
      };
      keyword = 56;
      module = 136;
      number = {
        bold = true;
        color = 94;
      };
      operator = {
        bold = true;
        color = 239;
      };
      property = 124;
      "property.builtin" = {
        bold = true;
        color = 124;
      };
      punctuation = 239;
      "punctuation.bracket" = 239;
      "punctuation.delimiter" = 239;
      "punctuation.special" = 239;
      string = 28;
      "string.special" = 30;
      tag = 18;
      type = 23;
      "type.builtin" = {
        bold = true;
        color = 23;
      };
      variable = 252;
      "variable.builtin" = {
        bold = true;
        color = 252;
      };
      "variable.parameter" = {
        color = 252;
        underline = true;
      };
    };
  };
  parserJson = pkgs.writeText "parser.json" (builtins.toJSON parserConfig);
in
{
  xdg.configFile."parser/config.json" = {
    source = parserJson;
    force = true;
  };
}

