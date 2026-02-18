#!/usr/bin/env nu

export def log_info [...msg] {
  print $"(ansi blue)[INFO](ansi reset) ($msg | str join ' ')"
}

export def log_warn [...msg] {
  eprintln $"(ansi yellow_bold)[WARN](ansi reset) ($msg | str join ' ')"
}

export def log_error [...msg] {
  eprintln $"(ansi red_bold)[ERROR](ansi reset) ($msg | str join ' ')"
}

export def log_success [...msg] {
  print $"(ansi green)[SUCCESS](ansi reset) ($msg | str join ' ')"
}
