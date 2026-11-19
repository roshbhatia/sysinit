use std/assert

def main [...files: path] {
    for file in $files { assert (open --raw $file | is-not-empty) }
}
