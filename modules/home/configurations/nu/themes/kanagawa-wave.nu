#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/kanagawa-wave.nu (begin)
let theme = {
  sumiInk0: "#16161d"
  sumiInk1: "#1f1f28"
  sumiInk2: "#2a2a37"
  sumiInk3: "#363646"
  sumiInk4: "#54546d"
  oldWhite: "#c8c093"
  fujiWhite: "#dcd7ba"
  fujiGray: "#727169"
  waveBlue1: "#223249"
  waveBlue2: "#2d4f67"
  waveAqua1: "#6a9589"
  waveAqua2: "#7aa89f"
  autumnGreen: "#76946a"
  autumnRed: "#c34043"
  autumnYellow: "#dca561"
  samuraiRed: "#e82424"
  roninYellow: "#ff9e3b"
  crystalBlue: "#7e9cd8"
  springViolet1: "#938aa9"
  springViolet2: "#9cabca"
  springBlue: "#7fb4ca"
  springGreen: "#98bb6c"
  boatYellow2: "#c0a36e"
  carpYellow: "#e6c384"
  sakuraPink: "#d27e99"
  waveRed: "#e46876"
  peachRed: "#ff5d62"
  surimiOrange: "#ffa066"
  oniViolet: "#957fb8"
}

let scheme = {
  recognized_command: $theme.crystalBlue
  unrecognized_command: $theme.fujiWhite
  constant: $theme.surimiOrange
  punctuation: $theme.springViolet2
  operator: $theme.springBlue
  string: $theme.springGreen
  virtual_text: $theme.fujiGray
  variable: { fg: $theme.oniViolet attr: i }
  filepath: $theme.carpYellow
}

$env.config.color_config = {
  separator: { fg: $theme.fujiGray attr: b }
  leading_trailing_space_bg: { fg: $theme.oniViolet attr: u }
  header: { fg: $theme.fujiWhite attr: b }
  row_index: $scheme.virtual_text
  record: $theme.fujiWhite
  list: $theme.fujiWhite
  hints: $scheme.virtual_text
  search_result: { fg: $theme.sumiInk1 bg: $theme.carpYellow }
  shape_closure: $theme.springBlue
  closure: $theme.springBlue
  shape_flag: { fg: $theme.autumnRed attr: i }
  shape_matching_brackets: { attr: u }
  shape_garbage: $theme.autumnRed
  shape_keyword: $theme.oniViolet
  shape_match_pattern: $theme.springGreen
  shape_signature: $theme.springBlue
  shape_table: $scheme.punctuation
  cell-path: $scheme.punctuation
  shape_list: $scheme.punctuation
  shape_record: $scheme.punctuation
  shape_vardecl: $scheme.variable
  shape_variable: $scheme.variable
  empty: { attr: n }
  filesize: {||
    if $in < 1kb {
      $theme.springBlue
    } else if $in < 10kb {
      $theme.springGreen
    } else if $in < 100kb {
      $theme.carpYellow
    } else if $in < 10mb {
      $theme.surimiOrange
    } else if $in < 100mb {
      $theme.oniViolet
    } else if $in < 1gb {
      $theme.autumnRed
    } else {
      $theme.oniViolet
    }
  }
  duration: {||
    if $in < 1day {
      $theme.springBlue
    } else if $in < 1wk {
      $theme.springGreen
    } else if $in < 4wk {
      $theme.carpYellow
    } else if $in < 12wk {
      $theme.surimiOrange
    } else if $in < 24wk {
      $theme.oniViolet
    } else if $in < 52wk {
      $theme.autumnRed
    } else {
      $theme.oniViolet
    }
  }
  date: {|| (date now) - $in |
    if $in < 1day {
      $theme.springBlue
    } else if $in < 1wk {
      $theme.springGreen
    } else if $in < 4wk {
      $theme.carpYellow
    } else if $in < 12wk {
      $theme.surimiOrange
    } else if $in < 24wk {
      $theme.oniViolet
    } else if $in < 52wk {
      $theme.autumnRed
    } else {
      $theme.oniViolet
    }
  }
  shape_external: $scheme.unrecognized_command
  shape_internalcall: $scheme.recognized_command
  shape_external_resolved: $scheme.recognized_command
  shape_block: $scheme.recognized_command
  block: $scheme.recognized_command
  shape_custom: $theme.oniViolet
  custom: $theme.oniViolet
  background: $theme.sumiInk1
  foreground: $theme.fujiWhite
  cursor: { bg: $theme.fujiWhite fg: $theme.sumiInk1 }
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
  shape_string_interpolation: $theme.oniViolet
  shape_raw_string: $scheme.string
  shape_externalarg: $scheme.string
}
$env.config.highlight_resolved_externals = true
$env.config.explore = {
    status_bar_background: { fg: $theme.fujiWhite, bg: $theme.sumiInk2 },
    command_bar_text: { fg: $theme.fujiWhite },
    highlight: { fg: $theme.sumiInk1, bg: $theme.carpYellow },
    status: {
        error: $theme.autumnRed,
        warn: $theme.carpYellow,
        info: $theme.crystalBlue,
    },
    selected_cell: { bg: $theme.crystalBlue fg: $theme.sumiInk1 },
}
# modules/darwin/home/nu/core/kanagawa-wave.nu (end)
