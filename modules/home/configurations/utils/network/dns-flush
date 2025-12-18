#!/usr/bin/env nu

def main [] {
    if $nu.os.family == "macos" {
        let result = (
            gum spin --spinner dot --title "Flushing DNS cache..." -- bash -c "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder" | complete
        )

        if $result.exit_code == 0 {
            print "✓ DNS cache flushed successfully"
        } else {
            print "✗ Failed to flush DNS cache" | ignore
            exit 1
        }
    } else if $nu.os.family == "linux" {
        let result = (
            gum spin --spinner dot --title "Flushing DNS cache..." -- bash -c "sudo systemctl restart systemd-resolved" | complete
        )

        if $result.exit_code == 0 {
            print "✓ DNS cache flushed successfully"
        } else {
            print "✗ Failed to flush DNS cache" | ignore
            exit 1
        }
    }
}
