#!/usr/bin/env nu

def main [] {
    let flush_cmd = match $nu.os.family {
        "macos" => "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
        "linux" => "sudo systemctl restart systemd-resolved"
        _ => {
            print $"✗ Unsupported OS: ($nu.os.family)"
            exit 1
        }
    }
    
    let result = (
        gum spin --spinner dot --title "Flushing DNS cache..." -- bash -c $flush_cmd | complete
    )

    if $result.exit_code == 0 {
        print "✓ DNS cache flushed successfully"
    } else {
        print "✗ Failed to flush DNS cache" | ignore
        exit 1
    }
}
