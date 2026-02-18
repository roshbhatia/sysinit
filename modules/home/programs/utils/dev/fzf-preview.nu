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

def infer-kind [path: string]: nothing -> string {
    if (($path | path type) == "dir") {
        "cd"
    } else if (($path | path type) == "symlink") {
        "symlink"
    } else if (($path | path type) == "file") {
        let mime_type = (^file --brief --mime-type $path | complete | get stdout | str trim | default "text/plain")
        
        if ($mime_type | str contains "image") {
            "chafa"
        } else if ($mime_type | str contains "tar") or ($mime_type | str contains "gzip") or ($mime_type | str contains "7z") or ($mime_type | str contains "zip") {
            "archive"
        } else {
            "bat"
        }
    } else {
        "unknown"
    }
}

def preview-dir [path: string] {
    if (which eza | is-empty) {
        ^ls -la $path
    } else {
        ^eza --color=always --icons=always --group-directories-first -1 $path
    }
}

def preview-image [path: string] {
    if (which chafa | is-empty) {
        print $"Image: ($path) (install chafa for preview)"
        return
    }
    
    let cols = (try { ^tput cols | str trim } catch { "80" })
    let lines = (try { ^tput lines | str trim } catch { "24" })
    let dim = $"($cols)x($lines)"
    
    ^chafa --size $dim $path
}

def preview-text [path: string] {
    if (which bat | is-empty) {
        open $path
    } else {
        ^bat --style=numbers --color=always --pager=never $path
    }
}

def preview-executable [path: string] {
    let basename = ($path | path basename)
    if (which man | is-empty) {
        print $"Executable: ($basename) (no man page available)"
    } else {
        try {
            ^man $basename
        } catch {
            print $"Executable: ($basename) (no man page available)"
        }
    }
}

def preview-archive [path: string] {
    let ext = $path | path parse | get extension
    match $ext {
        "gz" | "tgz" | "tar" | "tbz2" | "bz2" => {
            ^tar -tzvf $path | lines | first 20
        }
        "zip" => {
            ^unzip -l $path
        }
        "7z" => {
            ^7z l $path
        }
        _ => {
            print $"Archive: ($path)"
        }
    }
}

def preview-symlink [path: string] {
    let target = (^readlink -f $path | complete | get stdout | str trim | default "broken symlink")
    print $"Symlink: ($path) -> ($target)"
    
    if ($target | path exists) and (($target | path type) != "dir") {
        preview-text $target
    }
}

def main [
    target_arg?: string
    --kind (-k): string
] {
    let target = (get-target ($target_arg | default ""))
    if ($target == null) { return }
    
    let target = (normalize-target $target)
    if ($target == null) { return }

    let kind = if ($kind | is-empty) {
        infer-kind $target
    } else {
        $kind
    }

    match $kind {
        "cd" | "ls" => { preview-dir $target }
        "chafa" => { preview-image $target }
        "bat" | "nvim" => { preview-text $target }
        "archive" => { preview-archive $target }
        "symlink" => { preview-symlink $target }
        _ => {
            if (($target | path type) == "dir") {
                preview-dir $target
            } else if (($target | path type) == "symlink") {
                preview-symlink $target
            } else if (($target | path type) == "file") {
                let mime_type = (file --brief --mime-type $target err> /dev/null | default "text/plain")
                
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
    }
}
