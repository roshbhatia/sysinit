#!/usr/bin/env nu
# shellcheck disable=all
let theme = {
  base03: "#002b36"  # background
  base02: "#073642"  # background highlights
  base01: "#586e75"  # comments / secondary content
  base00: "#657b83"  # body text / default code / primary content
  base0: "#839496"   # primary content
  base1: "#93a1a1"   # optional emphasized content
  base2: "#eee8d5"   # background highlights (light theme)
  base3: "#fdf6e3"   # background (light theme)
  yellow: "#b58900"
  orange: "#cb4b16"
  red: "#dc322f"
  magenta: "#d33682"
  violet: "#6c71c4"
  blue: "#268bd2"
  cyan: "#2aa198"
  green: "#859900"
}

let scheme = {
  recognized_command: $theme.blue
  unrecognized_command: $theme.base0
  constant: $theme.orange
  punctuation: $theme.base01
  operator: $theme.cyan
  string: $theme.green
  virtual_text: $theme.base01
  variable: { fg: $theme.magenta attr: i }
  filepath: $theme.yellow
}

$env.config.color_config = {
  separator: { fg: $theme.base01 attr: b }
  leading_trailing_space_bg: { fg: $theme.violet attr: u }
  header: { fg: $theme.base1 attr: b }
  row_index: $scheme.virtual_text
  record: $theme.base0
  list: $theme.base0
  hints: $scheme.virtual_text
  search_result: { fg: $theme.base03 bg: $theme.yellow }
  shape_closure: $theme.cyan
  closure: $theme.cyan
  shape_flag: { fg: $theme.red attr: i }
  shape_matching_brackets: { attr: u }
  shape_garbage: $theme.red
  shape_keyword: $theme.violet
  shape_match_pattern: $theme.green
  shape_signature: $theme.cyan
  shape_table: $scheme.punctuation
  cell-path: $scheme.punctuation
  shape_list: $scheme.punctuation
  shape_record: $scheme.punctuation
  shape_vardecl: $scheme.variable
  shape_variable: $scheme.variable
  empty: { attr: n }
  filesize: {||
    if $in < 1kb {
      $theme.cyan
    } else if $in < 10kb {
      $theme.green
    } else if $in < 100kb {
      $theme.yellow
    } else if $in < 10mb {
      $theme.orange
    } else if $in < 100mb {
      $theme.magenta
    } else if $in < 1gb {
      $theme.red
    } else {
      $theme.violet
    }
  }
  duration: {||
    if $in < 1day {
      $theme.cyan
    } else if $in < 1wk {
      $theme.green
    } else if $in < 4wk {
      $theme.yellow
    } else if $in < 12wk {
      $theme.orange
    } else if $in < 24wk {
      $theme.magenta
    } else if $in < 52wk {
      $theme.red
    } else {
      $theme.violet
    }
  }
  date: {|| (date now) - $in |
    if $in < 1day {
      $theme.cyan
    } else if $in < 1wk {
      $theme.green
    } else if $in < 4wk {
      $theme.yellow
    } else if $in < 12wk {
      $theme.orange
    } else if $in < 24wk {
      $theme.magenta
    } else if $in < 52wk {
      $theme.red
    } else {
      $theme.violet
    }
  }
  shape_external: $scheme.unrecognized_command
  shape_internalcall: $scheme.recognized_command
  shape_external_resolved: $scheme.recognized_command
  shape_block: $scheme.recognized_command
  block: $scheme.recognized_command
  shape_custom: $theme.violet
  custom: $theme.violet
  background: $theme.base03
  foreground: $theme.base0
  cursor: { bg: $theme.base1 fg: $theme.base03 }
  shape_range: $scheme.operator
  range: $scheme.operator
  shape_pipe: $scheme.operator
  shape_operator: $scheme.operator
  shape_redirection: $scheme.operator
  glob: $scheme.filepath
  shape_directory: $scheme.filepath
  shape_filepath: $scheme.filepath
  shape_glob_interpolation: $scheme.filepath
  shape_globpattern: $scheme.filepath
  shape_int: $scheme.constant
  int: $scheme.constant
  bool: $scheme.constant
  float: $scheme.constant
  nothing: $scheme.constant
  binary: $scheme.constant
  shape_nothing: $scheme.constant
  shape_bool: $scheme.constant
  shape_float: $scheme.constant
  shape_binary: $scheme.constant
  shape_datetime: $scheme.constant
  shape_literal: $scheme.constant
  string: $scheme.string
  shape_string: $scheme.string
  shape_string_interpolation: $theme.magenta
  shape_raw_string: $scheme.string
  shape_externalarg: $scheme.string
}
$env.config.highlight_resolved_externals = true
$env.config.explore = {
    status_bar_background: { fg: $theme.base0, bg: $theme.base02 },
    command_bar_text: { fg: $theme.base0 },
    highlight: { fg: $theme.base03, bg: $theme.yellow },
    status: {
        error: $theme.red,
        warn: $theme.yellow,
        info: $theme.blue,
    },
    selected_cell: { bg: $theme.blue fg: $theme.base03 },
}
