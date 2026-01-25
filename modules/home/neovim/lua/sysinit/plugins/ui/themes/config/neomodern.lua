return function(theme_config)
  local code_style = {
    comments = "none",
    conditionals = "none",
    functions = "bold",
    keywords = "bold",
    headings = "italic",
    operators = "none",
    keyword_return = "bold",
    strings = "italic",
    variables = "none",
  }

  return {
    theme = theme_config.colorscheme,
    transparent = true,
    term_colors = true,
    alt_bg = true,
    show_eob = false,
    favor_treesitter_hl = true,
    code_style = code_style,
  }
end
