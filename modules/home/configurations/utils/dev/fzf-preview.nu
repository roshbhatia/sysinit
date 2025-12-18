#!/usr/bin/env nu

def get-target [target_arg: string] {
    let target = if ($target_arg | is-empty) { "" } else { $target_arg }
    
    if ($target | is-empty) or ($target == "$word") or ($target == "$realpath") {
        null
    } else {
        $target
    }
}

def normalize-target [target: string] {
    let target = ($target | str trim --right)
    let target = if ($target | str starts-with "~") {
        $target | str replace "~" $env.HOME
    } else {
        $target
    }
    
    let target = if not ($target | str starts-with "/") {
        $"(pwd)/($target)"
    } else {
        $target
    }

    if ($target | path exists) {
        $target | path expand
    } else {
        null
    }
}

def preview-dir [path: string] {
    if (which eza | is-empty) {
        ls -la $path
    } else {
        eza --color=always --icons=always --group-directories-first -1 $path
    }
}

def preview-image [path: string] {
    if (which chafa | is-empty) {
        print $"Image: ($path) (install chafa for preview)"
        return
    }
    
    let cols = (try { tput cols } catch { "80" })
    let lines = (try { tput lines } catch { "24" })
    let dim = $"($cols)x($lines)"
    
    chafa --size $dim $path 2> /dev/null
}

def preview-text [path: string] {
    if (which bat | is-empty) {
        open $path
    } else {
        bat --style=numbers --color=always --pager=never $path 2> /dev/null
    }
}

def preview-executable [path: string] {
    let basename = ($path | path basename)
    if (which man | is-empty) {
        print $"Executable: ($basename) (no man page available)"
    } else {
        try {
            man $basename 2> /dev/null
        } catch {
            print $"Executable: ($basename) (no man page available)"
        }
    }
}

def preview-archive [path: string] {
    match ($path | path extension) {
        "gz" | "tgz" | "tar" | "tbz2" | "bz2" => {
            tar -tzvf $path 2> /dev/null | head -20
        }
        "zip" => {
            unzip -l $path 2> /dev/null
        }
        "7z" => {
            7z l $path 2> /dev/null
        }
        _ => {
            print $"Archive: ($path)"
        }
    }
}

def preview-symlink [path: string] {
    let target = (readlink -f $path 2> /dev/null | default "broken symlink")
    print $"Symlink: ($path) -> ($target)"
    
    if ($target | path exists) and not ($target | path type --long | str contains "directory") {
        preview-text $target
    }
}

def main [target_arg?: string] {
    let target = (get-target ($target_arg | default ""))
    if ($target == null) { return }
    
    let target = (normalize-target $target)
    if ($target == null) { return }

    if ($target | path type --long | str contains "directory") {
        preview-dir $target
    } else if ($target | path type --long | str contains "symlink") {
        preview-symlink $target
    } else if ($target | path type --long | str contains "file") {
        let mime_type = (file --brief --mime-type $target 2> /dev/null | default "text/plain")
        
        if ($mime_type | str contains "image") {
            preview-image $target
        } else if ($mime_type | str contains "json") or ($mime_type | str contains "yaml") or ($mime_type | str contains "text") {
            preview-text $target
        } else if ($mime_type | str contains "pdf") {
            print $"PDF: ($target) (text extraction not supported)"
        } else if ($mime_type | str contains "tar") or ($mime_type | str contains "gzip") or ($mime_type | str contains "7z") or ($mime_type | str contains "zip") {
            preview-archive $target
        } else {
            (try { preview-text $target } catch { print $"No preview available for: ($target)" })
        }
    } else {
        print "No preview available"
    }
}
