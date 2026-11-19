def main [...files: string] {
    mut failures = []

    for file in ($files | where {|file| $file | path exists}) {
        mut opened = 0

        for line in (open --raw $file | lines | enumerate) {
            let number = $line.index + 1

            if $line.item == '# /// script' {
                $opened = $number
            } else if $opened > 0 and $line.item == '# ///' {
                $opened = 0
            } else if $opened > 0 and not ($line.item | str starts-with '#') {
                $failures = (
                    $failures
                    | append $"($file):($number): line is not a comment, so the `# /// script` block opened on line ($opened) never closes"
                )

                $opened = 0
            }
        }

        if $opened > 0 {
            $failures = (
                $failures
                | append $"($file):($opened): this `# /// script` block reaches the end of the file with no `# ///`"
            )
        }
    }

    if ($failures | is-not-empty) {
        print --stderr ($failures | str join "\n")

        exit 1
    }
}
