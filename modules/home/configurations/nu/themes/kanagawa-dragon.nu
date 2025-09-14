#!/usr/bin/env nu
# shellcheck disable=all
let theme = {
  dragonBlack0: "#0d0c0c"
  dragonBlack1: "#12120f"
  dragonBlack2: "#1d1c19"
  dragonBlack3: "#181616"
  dragonBlack4: "#282727"
  dragonBlack5: "#393836"
  dragonBlack6: "#625e5a"
  dragonWhite: "#c5c9c5"
  dragonGreen: "#87a987"
  dragonGreen2: "#8a9a7b"
  dragonPink: "#a292a3"
  dragonOrange: "#b6927b"
  dragonOrange2: "#b98d7b"
  dragonGray: "#a6a69c"
  dragonGray2: "#9e9b93"
  dragonGray3: "#7a8382"
  dragonBlue: "#8ba4b0"
  dragonBlue2: "#8ea4a2"
  dragonViolet: "#8992a7"
  dragonRed: "#c4746e"
  dragonAqua: "#8ea4a2"
  dragonAsh: "#737c73"
  dragonTeal: "#949fb5"
  dragonYellow: "#c4b28a"
}

let scheme = {
  recognized_command: $theme.dragonBlue
  unrecognized_command: $theme.dragonWhite
  constant: $theme.dragonOrange
  punctuation: $theme.dragonGray
  operator: $theme.dragonAqua
  string: $theme.dragonGreen
  virtual_text: $theme.dragonGray3
  variable: { fg: $theme.dragonViolet attr: i }
  filepath: $theme.dragonYellow
}

$env.config.color_config = {
  separator: { fg: $theme.dragonGray3 attr: b }
  leading_trailing_space_bg: { fg: $theme.dragonViolet attr: u }
  header: { fg: $theme.dragonWhite attr: b }
  row_index: $scheme.virtual_text
  record: $theme.dragonWhite
  list: $theme.dragonWhite
  hints: $scheme.virtual_text
  search_result: { fg: $theme.dragonBlack3 bg: $theme.dragonYellow }
  shape_closure: $theme.dragonAqua
  closure: $theme.dragonAqua
  shape_flag: { fg: $theme.dragonRed attr: i }
  shape_matching_brackets: { attr: u }
  shape_garbage: $theme.dragonRed
  shape_keyword: $theme.dragonViolet
  shape_match_pattern: $theme.dragonGreen
  shape_signature: $theme.dragonAqua
  shape_table: $scheme.punctuation
  cell-path: $scheme.punctuation
  shape_list: $scheme.punctuation
  shape_record: $scheme.punctuation
  shape_vardecl: $scheme.variable
  shape_variable: $scheme.variable
  empty: { attr: n }
  filesize: {||
    if $in < 1kb {
      $theme.dragonAqua
    } else if $in < 10kb {
      $theme.dragonGreen
    } else if $in < 100kb {
      $theme.dragonYellow
    } else if $in < 10mb {
      $theme.dragonOrange
    } else if $in < 100mb {
      $theme.dragonViolet
    } else if $in < 1gb {
      $theme.dragonRed
    } else {
      $theme.dragonViolet
    }
  }
  duration: {||
    if $in < 1day {
      $theme.dragonAqua
    } else if $in < 1wk {
      $theme.dragonGreen
    } else if $in < 4wk {
      $theme.dragonYellow
    } else if $in < 12wk {
      $theme.dragonOrange
    } else if $in < 24wk {
      $theme.dragonViolet
    } else if $in < 52wk {
      $theme.dragonRed
    } else {
      $theme.dragonViolet
    }
  }
  date: {|| (date now) - $in |
    if $in < 1day {
      $theme.dragonAqua
    } else if $in < 1wk {
      $theme.dragonGreen
    } else if $in < 4wk {
      $theme.dragonYellow
    } else if $in < 12wk {
      $theme.dragonOrange
    } else if $in < 24wk {
      $theme.dragonViolet
    } else if $in < 52wk {
      $theme.dragonRed
    } else {
      $theme.dragonViolet
    }
  }
  shape_external: $scheme.unrecognized_command
  shape_internalcall: $scheme.recognized_command
  shape_external_resolved: $scheme.recognized_command
  shape_block: $scheme.recognized_command
  block: $scheme.recognized_command
  shape_custom: $theme.dragonViolet
  custom: $theme.dragonViolet
  background: $theme.dragonBlack3
  foreground: $theme.dragonWhite
  cursor: { bg: $theme.dragonWhite fg: $theme.dragonBlack3 }
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
  shape_string_interpolation: $theme.dragonViolet
  shape_raw_string: $scheme.string
  shape_externalarg: $scheme.string
}
$env.config.highlight_resolved_externals = true
$env.config.explore = {
    status_bar_background: { fg: $theme.dragonWhite, bg: $theme.dragonBlack2 },
    command_bar_text: { fg: $theme.dragonWhite },
    highlight: { fg: $theme.dragonBlack3, bg: $theme.dragonYellow },
    status: {
        error: $theme.dragonRed,
        warn: $theme.dragonYellow,
        info: $theme.dragonBlue,
    },
    selected_cell: { bg: $theme.dragonBlue fg: $theme.dragonBlack3 },
}
