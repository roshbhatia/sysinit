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
        background = "#3b4252";
      };
      constructor = "#e5c890";
      embedded = {
        color = "#81c8be";
        italic = true;
      };
      function = {
        bold = true;
        color = "#8caaee";
        underline = true;
      };
      "function.builtin" = {
        bold = true;
        color = "#99d1db";
        background = "#3b4252";
      };
      keyword = {
        bold = true;
        color = "#f4b8e4";
      };
      module = {
        color = "#e5c890";
        italic = true;
      };
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
      "punctuation.bracket" = {
        bold = true;
        color = "#737994";
      };
      "punctuation.delimiter" = {
        color = "#737994";
      };
      "punctuation.special" = {
        bold = true;
        color = "#81c8be";
      };
      string = {
        color = "#a6d189";
        italic = true;
      };
      "string.special" = {
        bold = true;
        color = "#81c8be";
      };
      tag = {
        bold = true;
        color = "#f4b8e4";
      };
      type = {
        bold = true;
        color = "#99d1db";
      };
      "type.builtin" = {
        bold = true;
        color = "#85c1dc";
        underline = true;
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
