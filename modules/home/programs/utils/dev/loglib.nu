# Nushell version of loglib - provides logging functions
# This is a placeholder that can be expanded with nushell-specific logging

def log_info [msg: string] {
  print $"[INFO] ($msg)"
}

def log_success [msg: string] {
  print $"[✓] ($msg)"
}

def log_error [msg: string] {
  print $"[ERROR] ($msg)" | print --stderr
}

def log_warn [msg: string] {
  print $"[WARN] ($msg)"
}
