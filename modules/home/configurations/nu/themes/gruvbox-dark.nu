#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/gruvbox_dark.nu (begin)
let theme = {
  bg0_h: "#1d2021"
  bg0: "#282828"
  bg0_s: "#32302f"
  bg1: "#3c3836"
  bg2: "#504945"
  bg3: "#665c54"
  bg4: "#7c6f64"
  fg0: "#fbf1c7"
  fg1: "#ebdbb2"
  fg2: "#d5c4a1"
  fg3: "#bdae93"
  fg4: "#a89984"
  gray: "#928374"
  red: "#fb4934"
  green: "#b8bb26"
  yellow: "#fabd2f"
  blue: "#83a598"
  purple: "#d3869b"
  aqua: "#8ec07c"
  orange: "#fe8019"
  neutral_red: "#cc241d"
  neutral_green: "#98971a"
  neutral_yellow: "#d79921"
  neutral_blue: "#458588"
  neutral_purple: "#b16286"
  neutral_aqua: "#689d6a"
}

let scheme = {
  recognized_command: $theme.blue
  unrecognized_command: $theme.fg1
  constant: $theme.orange
  punctuation: $theme.fg4
  operator: $theme.aqua
  string: $theme.green
  virtual_text: $theme.gray
  variable: { fg: $theme.purple attr: i }
  filepath: $theme.yellow
}

$env.config.color_config = {
  separator: { fg: $theme.gray attr: b }
  leading_trailing_space_bg: { fg: $theme.purple attr: u }
  header: { fg: $theme.fg0 attr: b }
  row_index: $scheme.virtual_text
  record: $theme.fg1
  list: $theme.fg1
  hints: $scheme.virtual_text
  search_result: { fg: $theme.bg0 bg: $theme.yellow }
  shape_closure: $theme.aqua
  closure: $theme.aqua
  shape_flag: { fg: $theme.red attr: i }
  shape_matching_brackets: { attr: u }
  shape_garbage: $theme.red
  shape_keyword: $theme.purple
  shape_match_pattern: $theme.green
  shape_signature: $theme.aqua
  shape_table: $scheme.punctuation
  cell-path: $scheme.punctuation
  shape_list: $scheme.punctuation
  shape_record: $scheme.punctuation
  shape_vardecl: $scheme.variable
  shape_variable: $scheme.variable
  empty: { attr: n }
  filesize: {||
    if $in < 1kb {
      $theme.aqua
    } else if $in < 10kb {
      $theme.green
    } else if $in < 100kb {
      $theme.yellow
    } else if $in < 10mb {
      $theme.orange
    } else if $in < 100mb {
      $theme.purple
    } else if $in < 1gb {
      $theme.red
    } else {
      $theme.purple
    }
  }
  duration: {||
    if $in < 1day {
      $theme.aqua
    } else if $in < 1wk {
      $theme.green
    } else if $in < 4wk {
      $theme.yellow
    } else if $in < 12wk {
      $theme.orange
    } else if $in < 24wk {
      $theme.purple
    } else if $in < 52wk {
      $theme.red
    } else {
      $theme.purple
    }
  }
  date: {|| (date now) - $in |
    if $in < 1day {
      $theme.aqua
    } else if $in < 1wk {
      $theme.green
    } else if $in < 4wk {
      $theme.yellow
    } else if $in < 12wk {
      $theme.orange
    } else if $in < 24wk {
      $theme.purple
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
  background: $theme.bg0
  foreground: $theme.fg1
  cursor: { bg: $theme.fg0 fg: $theme.bg0 }
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
  shape_string_interpolation: $theme.purple
  shape_raw_string: $scheme.string
  shape_externalarg: $scheme.string
}
$env.config.highlight_resolved_externals = true
$env.config.explore = {
    status_bar_background: { fg: $theme.fg1, bg: $theme.bg1 },
    command_bar_text: { fg: $theme.fg1 },
    highlight: { fg: $theme.bg0, bg: $theme.yellow },
    status: {
        error: $theme.red,
        warn: $theme.yellow,
        info: $theme.blue,
    },
    selected_cell: { bg: $theme.blue fg: $theme.bg0 },
}
# modules/darwin/home/nu/core/gruvbox_dark.nu (end)
