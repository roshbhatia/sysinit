#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/nord_dark.nu (begin)
let theme = {
  # Polar Night (darker backgrounds)
  nord0: "#2e3440"
  nord1: "#3b4252"
  nord2: "#434c5e"
  nord3: "#4c566a"
  # Snow Storm (lighter foregrounds)
  nord4: "#d8dee9"
  nord5: "#e5e9f0"
  nord6: "#eceff4"
  # Frost (blues and teals)
  nord7: "#8fbcbb"
  nord8: "#88c0d0"
  nord9: "#81a1c1"
  nord10: "#5e81ac"
  # Aurora (accent colors)
  nord11: "#bf616a"  # red
  nord12: "#d08770"  # orange
  nord13: "#ebcb8b"  # yellow
  nord14: "#a3be8c"  # green
  nord15: "#b48ead"  # purple
  # Convenience aliases
  base: "#2e3440"
  text: "#eceff4"
  red: "#bf616a"
  orange: "#d08770"
  yellow: "#ebcb8b"
  green: "#a3be8c"
  blue: "#5e81ac"
  purple: "#b48ead"
  cyan: "#88c0d0"
  teal: "#8fbcbb"
}

let scheme = {
  recognized_command: $theme.blue
  unrecognized_command: $theme.text
  constant: $theme.orange
  punctuation: $theme.nord3
  operator: $theme.cyan
  string: $theme.green
  virtual_text: $theme.nord2
  variable: { fg: $theme.nord4 attr: i }
  filepath: $theme.yellow
}

$env.config.color_config = {
  separator: { fg: $theme.nord2 attr: b }
  leading_trailing_space_bg: { fg: $theme.nord9 attr: u }
  header: { fg: $theme.text attr: b }
  row_index: $scheme.virtual_text
  record: $theme.text
  list: $theme.text
  hints: $scheme.virtual_text
  search_result: { fg: $theme.base bg: $theme.yellow }
  shape_closure: $theme.teal
  closure: $theme.teal
  shape_flag: { fg: $theme.red attr: i }
  shape_matching_brackets: { attr: u }
  shape_garbage: $theme.red
  shape_keyword: $theme.purple
  shape_match_pattern: $theme.green
  shape_signature: $theme.teal
  shape_table: $scheme.punctuation
  cell-path: $scheme.punctuation
  shape_list: $scheme.punctuation
  shape_record: $scheme.punctuation
  shape_vardecl: $scheme.variable
  shape_variable: $scheme.variable
  empty: { attr: n }
  filesize: {||
    if $in < 1kb {
      $theme.teal
    } else if $in < 10kb {
      $theme.green
    } else if $in < 100kb {
      $theme.yellow
    } else if $in < 10mb {
      $theme.orange
    } else if $in < 100mb {
      $theme.red
    } else if $in < 1gb {
      $theme.red
    } else {
      $theme.purple
    }
  }
  duration: {||
    if $in < 1day {
      $theme.teal
    } else if $in < 1wk {
      $theme.green
    } else if $in < 4wk {
      $theme.yellow
    } else if $in < 12wk {
      $theme.orange
    } else if $in < 24wk {
      $theme.red
    } else if $in < 52wk {
      $theme.red
    } else {
      $theme.purple
    }
  }
  date: {|| (date now) - $in |
    if $in < 1day {
      $theme.teal
    } else if $in < 1wk {
      $theme.green
    } else if $in < 4wk {
      $theme.yellow
    } else if $in < 12wk {
      $theme.orange
    } else if $in < 24wk {
      $theme.red
    } else if $in < 52wk {
      $theme.red
    } else {
      $theme.purple
    }
  }
  shape_external: $scheme.unrecognized_command
  shape_internalcall: $scheme.recognized_command
  shape_external_resolved: $scheme.recognized_command
  shape_block: $scheme.recognized_command
  block: $scheme.recognized_command
  shape_custom: $theme.purple
  custom: $theme.purple
  background: $theme.base
  foreground: $theme.text
  cursor: { bg: $theme.nord4 fg: $theme.base }
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
  shape_string_interpolation: $theme.nord4
  shape_raw_string: $scheme.string
  shape_externalarg: $scheme.string
}
$env.config.highlight_resolved_externals = true
$env.config.explore = {
    status_bar_background: { fg: $theme.text, bg: $theme.nord1 },
    command_bar_text: { fg: $theme.text },
    highlight: { fg: $theme.base, bg: $theme.yellow },
    status: {
        error: $theme.red,
        warn: $theme.yellow,
        info: $theme.blue,
    },
    selected_cell: { bg: $theme.blue fg: $theme.base },
}
# modules/darwin/home/nu/core/nord_dark.nu (end)
