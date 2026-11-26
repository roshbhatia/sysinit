export def wezterm-socket [] {
    let explicit = $env.WEZTERM_UNIX_SOCKET? | default ''

    if $explicit != '' {
        return (
            try {
                $explicit | path expand --strict
            } catch {
                $explicit
            }
        )
    }

    let fallback = $env.HOME | path join .local share wezterm

    let sockets = if $nu.os-info.name == macos {
        [
            ($fallback | path join default-org.wezfurlong.wezterm)
        ]
    } else {
        let runtime = if $env.XDG_RUNTIME_DIR? != null {
            $env.XDG_RUNTIME_DIR | path join wezterm
        } else {
            $fallback
        }

        let display = $env.DISPLAY? | default ':0'

        let names = if $env.WAYLAND_DISPLAY? != null {
            [$"wayland-($env.WAYLAND_DISPLAY)-org.wezfurlong.wezterm"]
        } else {
            []
        }

        $names | append $"x11-($display)-org.wezfurlong.wezterm" | each {|name| $runtime | path join $name }
    }

    $sockets | each {|socket| try { $socket | path expand --strict } } | first | default ''
}

export def wezterm-mux-identity [socket: string] {
    if $socket == '' { return null }

    let result = ^stat -L --printf '%d:%i:%.9Y' $socket | complete

    if $result.exit_code == 0 {
        $result.stdout | str trim
    }
}
