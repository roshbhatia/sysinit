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
        color = "#ca9ee6";
        italic = true;
      };
      comment = {
        color = "#626880";
        italic = true;
      };
      constant = "#e78284";
      "constant.builtin" = {
        bold = true;
        color = "#ef9f76";
      };
      constructor = "#e5c890";
      embedded = null;
      function = "#8caaee";
      "function.builtin" = {
        bold = true;
        color = "#99d1db";
      };
      keyword = "#f4b8e4";
      module = "#e5c890";
      number = {
        bold = true;
        color = "#ef9f76";
      };
      operator = {
        bold = true;
        color = "#737994";
      };
      property = "#ca9ee6";
      "property.builtin" = {
        bold = true;
        color = "#f4b8e4";
      };
      punctuation = "#626880";
      "punctuation.bracket" = "#737994";
      "punctuation.delimiter" = "#737994";
      "punctuation.special" = "#81c8be";
      string = "#a6d189";
      "string.special" = "#81c8be";
      tag = "#f4b8e4";
      type = "#99d1db";
      "type.builtin" = {
        bold = true;
        color = "#85c1dc";
      };
      variable = "#b5bfe2";
      "variable.builtin" = {
        bold = true;
        color = "#eebebe";
      };
      "variable.parameter" = {
        color = "#c6d0f5";
        italic = true;
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
