use std/assert

def main [config: path, script: path] {
    $env.HOME = $env.TMPDIR | path join home

    mkdir $env.HOME ($env.TMPDIR | path join fixtures)

    cd ($env.TMPDIR | path join fixtures)

    touch completion-target.txt unrelated.txt

    let result = ^$nu.current-exe --config $config $script | complete

    assert equal $result.exit_code 0 $result.stderr

    assert equal $result.stderr ''
}
