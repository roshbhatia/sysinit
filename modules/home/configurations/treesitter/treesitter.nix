{
  lib,
  config,
  pkgs,
  ...
}:
let
  treesitterConfig = {
    parser-directories = [
      "${config.home.homeDirectory}/.local/share/nvim/lazy/nvim-treesitter/parser"
      "${config.home.homeDirectory}/.local/share/nvim/lazy/nvim-treesitter/queries"
      "${config.home.homeDirectory}/github/tree-sitter-grammars"
    ];
    theme = {
      attribute = {
        color = "#cba6f7";
        italic = true;
      };
      comment = {
        color = "#6c7086";
        italic = true;
      };
      constant = "#f38ba8";
      "constant.builtin" = {
        bold = true;
        color = "#f38ba8";
      };
      constructor = "#f9e2af";
      embedded = null;
      function = "#89b4fa";
      "function.builtin" = {
        bold = true;
        color = "#89b4fa";
      };
      keyword = "#f5c2e7";
      module = "#f9e2af";
      number = {
        bold = true;
        color = "#f38ba8";
      };
      operator = {
        bold = true;
        color = "#6c7086";
      };
      property = "#cba6f7";
      "property.builtin" = {
        bold = true;
        color = "#cba6f7";
      };
      punctuation = "#6c7086";
      "punctuation.bracket" = "#6c7086";
      "punctuation.delimiter" = "#6c7086";
      "punctuation.special" = "#6c7086";
      string = "#a6e3a1";
      "string.special" = "#94e2d5";
      tag = "#f5c2e7";
      type = "#89dceb";
      "type.builtin" = {
        bold = true;
        color = "#89dceb";
      };
      variable = "#cdd6f4";
      "variable.builtin" = {
        bold = true;
        color = "#cdd6f4";
      };
      "variable.parameter" = {
        color = "#cdd6f4";
        underline = true;
      };
    };
  };
  treesitterJson = pkgs.writeText "treesitter.json" (builtins.toJSON treesitterConfig);
in
{
  xdg.configFile."tree-sitter/config.json" = {
    source = treesitterJson;
    force = true;
  };
}
