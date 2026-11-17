def main [file: path] {
    if not (nu-check --debug ($file | path expand)) { exit 1 }
}
