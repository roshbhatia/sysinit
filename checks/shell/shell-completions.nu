use std/assert

def main [root: path] {
    for file in [share/bash-completion/completions/ere.bash share/fish/vendor_completions.d/ere.fish] {
        assert (open --raw ($root | path join $file) | is-not-empty)
    }
}
