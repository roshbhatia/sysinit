#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/rose_pine_moon.nu (begin)
let theme = {
  base: "#232136"
  surface: "#2a273f"
  overlay: "#393552"
  muted: "#6e6a86"
  subtle: "#908caa"
  text: "#e0def4"
  love: "#eb6f92"
  gold: "#f6c177"
  rose: "#ea9a97"
  pine: "#3e8fb0"
  foam: "#9ccfd8"
  iris: "#c4a7e7"
  highlight_low: "#2a283e"
  highlight_med: "#44415a"
  highlight_high: "#56526e"
}

let scheme = {
  recognized_command: $theme.pine
  unrecognized_command: $theme.text
  constant: $theme.gold
  punctuation: $theme.subtle
  operator: $theme.foam
  string: $theme.foam
  virtual_text: $theme.muted
  variable: { fg: $theme.rose attr: i }
  filepath: $theme.gold
}

$env.config.color_config = {
  separator: { fg: $theme.muted attr: b }
  leading_trailing_space_bg: { fg: $theme.iris attr: u }
  header: { fg: $theme.text attr: b }
  row_index: $scheme.virtual_text
  record: $theme.text
  list: $theme.text
  hints: $scheme.virtual_text
  search_result: { fg: $theme.base bg: $theme.gold }
  shape_closure: $theme.foam
  closure: $theme.foam
  shape_flag: { fg: $theme.love attr: i }
  shape_matching_brackets: { attr: u }
  shape_garbage: $theme.love
  shape_keyword: $theme.iris
  shape_match_pattern: $theme.foam
  shape_signature: $theme.foam
  shape_table: $scheme.punctuation
  cell-path: $scheme.punctuation
  shape_list: $scheme.punctuation
  shape_record: $scheme.punctuation
  shape_vardecl: $scheme.variable
  shape_variable: $scheme.variable
  empty: { attr: n }
  filesize: {||
    if $in < 1kb {
      $theme.foam
    } else if $in < 10kb {
      $theme.foam
    } else if $in < 100kb {
      $theme.gold
    } else if $in < 10mb {
      $theme.gold
    } else if $in < 100mb {
      $theme.rose
    } else if $in < 1gb {
      $theme.love
    } else {
      $theme.iris
    }
  }
  duration: {||
    if $in < 1day {
      $theme.foam
    } else if $in < 1wk {
      $theme.foam
    } else if $in < 4wk {
      $theme.gold
    } else if $in < 12wk {
      $theme.gold
    } else if $in < 24wk {
      $theme.rose
    } else if $in < 52wk {
      $theme.love
    } else {
      $theme.iris
    }
  }
  date: {|| (date now) - $in |
    if $in < 1day {
      $theme.foam
    } else if $in < 1wk {
      $theme.foam
    } else if $in < 4wk {
      $theme.gold
    } else if $in < 12wk {
      $theme.gold
    } else if $in < 24wk {
      $theme.rose
    } else if $in < 52wk {
      $theme.love
    } else {
      $theme.iris
    }
  }
  shape_external: $scheme.unrecognized_command
  shape_internalcall: $scheme.recognized_command
  shape_external_resolved: $scheme.recognized_command
  shape_block: $scheme.recognized_command
  block: $scheme.recognized_command
  shape_custom: $theme.iris
  custom: $theme.iris
  background: $theme.base
  foreground: $theme.text
  cursor: { bg: $theme.text fg: $theme.base }
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
  shape_string_interpolation: $theme.rose
  shape_raw_string: $scheme.string
  shape_externalarg: $scheme.string
}
$env.config.highlight_resolved_externals = true
$env.config.explore = {
    status_bar_background: { fg: $theme.text, bg: $theme.surface },
    command_bar_text: { fg: $theme.text },
    highlight: { fg: $theme.base, bg: $theme.gold },
    status: {
        error: $theme.love,
        warn: $theme.gold,
        info: $theme.pine,
    },
    selected_cell: { bg: $theme.pine fg: $theme.base },
}
# modules/darwin/home/nu/core/rose_pine_moon.nu (end)