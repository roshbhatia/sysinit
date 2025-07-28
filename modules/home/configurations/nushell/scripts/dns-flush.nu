# Nushell version of dns-flush (zsh/bin/dns-flush)
def main [] {
  try {
    gum spin --spinner dot --title "Flushing DNS cache..." -- ^sudo dscacheutil -flushcache; ^sudo killall -HUP mDNSResponder
    gum style --foreground "#00ff00" "✓ DNS cache flushed successfully"
  } catch {
    print (ansi red_bold)"ERROR: Failed to flush DNS cache"(ansi reset)
  }
}

main
