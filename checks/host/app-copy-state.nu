use std/assert

def fixture [name: string = 'Test App.app'] {
    let root = mktemp -d

    let source = $root | path join source

    let target = $root | path join target

    let original = $root | path join original.app

    let app = $target | path join $name

    mkdir $source $target $original $app

    ^ln -s $original ($source | path join $name)

    'signed' | save ($app | path join payload)

    {
        root: $root
        source: $source
        target: $target
        original: $original
        app: $app
        name: $name
        state: ($root | path join state.json)
    }
}

def run-state [fixture: record, operation: string, ...extra: string] {
    let shell = $nu.current-exe

    ^$shell --no-config-file $env.APP_COPY_TEST_HELPER $operation $fixture.source $fixture.target $fixture.state --codesign $env.APP_COPY_TEST_COMMAND ...$extra | complete
}

def expect-code [
    code: int
    fixture: record
    operation: string
    extra: list<string> = []
] {
    let result = run-state $fixture $operation ...$extra

    assert equal $result.exit_code $code $result.stderr
}

def record [fixture: record] {
    expect-code 0 $fixture record

    assert equal (^stat --format=%a $fixture.state | str trim) '600'

    expect-code 0 $fixture check
}

def update-source [fixture: record, payload: string] {
    let updated = $fixture.root | path join updated.app

    mkdir $updated

    $payload | save ($updated | path join payload)

    rm ($fixture.source | path join $fixture.name)

    ^ln -s $updated ($fixture.source | path join $fixture.name)
}

def main [helper: path, command: path] {
    $env.APP_COPY_TEST_HELPER = $helper

    $env.APP_COPY_TEST_COMMAND = $command

    let unchanged = fixture

    expect-code 1 $unchanged check

    record $unchanged

    let tampered = fixture

    record $tampered

    'tampered' | save --force ($tampered.app | path join payload)

    expect-code 1 $tampered check

    let previous = open --raw $tampered.state

    expect-code 1 $tampered record

    assert equal (open --raw $tampered.state) $previous

    let source_changed = fixture

    record $source_changed

    update-source $source_changed updated

    expect-code 1 $source_changed check

    let missing = fixture

    record $missing

    rm --recursive $missing.app

    expect-code 1 $missing check

    let extra = fixture

    record $extra

    mkdir ($extra.target | path join Extra.app)

    expect-code 1 $extra check

    let corrupt = fixture

    record $corrupt

    'invalid' | save --force $corrupt.state

    expect-code 1 $corrupt check

    let linked = fixture

    record $linked

    rm --recursive $linked.app

    ^ln -s $linked.original $linked.app

    expect-code 1 $linked check

    for name in ['Test App.app' 'Test [a]*?.app'] {
        let preserved = fixture $name

        record $preserved

        let before = ^stat '--format=%i %y' ($preserved.app | path join payload)

        'unsigned store payload' | save ($preserved.original | path join payload)

        mkdir ($preserved.source | path join Another.app)

        'new application' | save ($preserved.source | path join Another.app payload)

        expect-code 0 $preserved sync

        assert equal (^stat '--format=%i %y' ($preserved.app | path join payload)) $before

        assert equal (open --raw ($preserved.app | path join payload)) signed

        assert equal (open --raw ($preserved.target | path join Another.app payload)) 'new application'
    }

    let repaired = fixture

    record $repaired

    update-source $repaired updated

    expect-code 0 $repaired sync

    assert equal (open --raw ($repaired.app | path join payload)) updated

    let protected = [--protect-running '["Test App"]' --pgrep $command]

    let running = fixture

    record $running

    'changed' | save --force ($running.app | path join payload)

    with-env {APP_COPY_TEST_PGREP_EXIT: '0'} {
    expect-code 1 $running preflight $protected
    expect-code 1 $running sync $protected
  }

    assert equal (open --raw ($running.app | path join payload)) changed

    let active_unchanged = fixture

    record $active_unchanged

    mkdir ($active_unchanged.source | path join Another.app)

    'new' | save ($active_unchanged.source | path join Another.app payload)

    with-env {APP_COPY_TEST_PGREP_EXIT: '0'} {
    expect-code 0 $active_unchanged preflight $protected
    expect-code 0 $active_unchanged sync $protected
  }

    assert equal (open --raw ($active_unchanged.app | path join payload)) signed

    let closed = fixture

    'replacement' | save ($closed.original | path join payload)

    with-env {APP_COPY_TEST_PGREP_EXIT: '1'} {
    expect-code 0 $closed preflight $protected
    expect-code 0 $closed sync $protected
  }

    assert equal (open --raw ($closed.app | path join payload)) replacement

    let failed_process_check = fixture

    with-env {APP_COPY_TEST_PGREP_EXIT: '2'} {
    expect-code 1 $failed_process_check preflight $protected
    expect-code 1 $failed_process_check sync $protected
  }

    assert equal (open --raw ($failed_process_check.app | path join payload)) signed

    let removed_source = fixture

    record $removed_source

    rm ($removed_source.source | path join $removed_source.name)

    with-env {APP_COPY_TEST_PGREP_EXIT: '0'} {
    expect-code 1 $removed_source preflight $protected
    expect-code 1 $removed_source sync $protected
  }

    assert ($removed_source.app | path exists)

    print 'app copy: signature cache, atomic state, source drift, rsync exclusions and running-app boundaries passed'
}
