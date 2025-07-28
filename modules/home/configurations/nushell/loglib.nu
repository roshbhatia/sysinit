def log_info [msg: string] {
  print $"(ansi green_bold)INFO(ansi reset): ($msg)"
}
def log_warn [msg: string] {
  print $"(ansi yellow_bold)WARN(ansi reset): ($msg)"
}
def log_error [msg: string] {
  print $"(ansi red_bold)ERROR(ansi reset): ($msg)"
}
