use std/assert

def execute [path: path, sql: string] {
    let result = ^sqlite3 -bail $path $sql | complete

    assert equal $result.exit_code 0 $result.stderr
}

def rows [path: path, sql: string] {
    let result = ^sqlite3 -bail -json $path $sql | complete

    assert equal $result.exit_code 0 $result.stderr

    $result.stdout | from json
}

def wait-for [path: path] {
    let deadline = (date now) + 10sec

    while not ($path | path exists) {
        assert ((date now) < $deadline) $'timed out waiting for ($path)'

        sleep 10ms
    }
}

def check [script: path, waiter: path] {
    let root = mktemp --directory --tmpdir-path /tmp | path expand --strict

    try {
        let path = $root | path join metrics-db

        let now = 2_000_000_000

        let preserved = [
            1
            2
            3
            4
            7
            8
            9
        ] | enumerate | each {|row|
            {id: ($row.index + 1), kind: $row.item, now: $now} | format pattern "INSERT INTO metrics VALUES ({id}, {kind}, {now}, 'preserved');"
        } | str join "\n"

        let seed = {
            now: $now
            old: ($now - 8 * 86400)
            preserved: $preserved
        } | format pattern "PRAGMA journal_mode=WAL;
          CREATE TABLE metrics (id INTEGER PRIMARY KEY, event_kind INTEGER, event_ts INTEGER, event_json TEXT);
          CREATE TABLE unrelated (value TEXT);
          INSERT INTO unrelated VALUES ('preserved');
          {preserved}
          INSERT INTO metrics VALUES (10, 5, {old}, replace(hex(zeroblob(400000)), '00', 'old'));
          INSERT INTO metrics VALUES (11, 5, {now}, replace(hex(zeroblob(100000)), '00', 'older recent'));
          INSERT INTO metrics VALUES (12, 6, {now}, 'newest'), (13, 5, NULL, 'unknown time'), (14, 100, {now}, 'unknown kind');"

        execute $path $seed

        let ready = $root | path join ready

        let insert = $root | path join insert

        let inserted = $root | path join inserted

        let lock = $root | path join lock

        let locked = $root | path join locked

        let release = $root | path join release

        let wait_insert = [$nu.current-exe --no-config-file $waiter $insert] | each { to json --raw } | str join ' '

        let wait_lock = [$nu.current-exe --no-config-file $waiter $lock] | each { to json --raw } | str join ' '

        let wait_release = [$nu.current-exe --no-config-file $waiter $release] | each { to json --raw } | str join ' '

        let sql = {
            ready: ($ready | to json --raw)
            wait_insert: $wait_insert
            now: $now
            inserted: ($inserted | to json --raw)
            wait_lock: $wait_lock
            locked: ($locked | to json --raw)
            wait_release: $wait_release
        } | format pattern "SELECT count(*) FROM metrics;
.shell touch {ready}
.shell {wait_insert}
INSERT INTO metrics VALUES (15, 9, {now}, 'writer stays usable');
.shell touch {inserted}
.shell {wait_lock}
BEGIN IMMEDIATE;
INSERT INTO metrics VALUES (16, 5, {now}, 'uncommitted');
.shell touch {locked}
.shell {wait_release}
ROLLBACK;
"

        let writer = job spawn --auto-kill {
            let result = $sql | ^sqlite3 -bail $path | complete
            $result | job send 0
        }

        try {
            wait-for $ready

            let before = rows $path 'SELECT * FROM metrics ORDER BY id'

            let expected = $before | where {|row| $row.id not-in [10 11]} | to json --raw | hash sha256

            let snapshot = $before | to json --raw | hash sha256

            let dry_run = maintain $path 100 7 --now $now

            assert equal $dry_run.status would-prune

            assert equal $dry_run.candidates 2

            assert equal (
                rows $path 'SELECT * FROM metrics ORDER BY id'
                | to json --raw
                | hash sha256
            ) $snapshot

            let applied = maintain $path 100 7 --apply --now $now

            assert equal $applied.deleted 2

            assert equal $applied.status compacted

            assert ($applied.after_bytes < $applied.before_bytes)

            assert equal (
                rows $path 'SELECT * FROM metrics ORDER BY id'
                | to json --raw
                | hash sha256
            ) $expected

            assert equal (rows $path 'SELECT * FROM unrelated') [[value]; [preserved]]

            touch $insert

            wait-for $inserted

            assert equal (maintain $path 100 7 --apply --now $now | get status) within-limit

            touch $lock

            wait-for $locked

            let failed = try {
                maintain $path 100 7 --apply --now $now

                null
            } catch {|failure|
                $failure.msg
            }

            assert ($failed != null and ($failed | str contains locked)) 'competing writer was not respected'

            let busy = ^$nu.current-exe --no-config-file $script --database $path --max-session-bytes 100 --apply | complete

            assert equal $busy.exit_code 0 $busy.stderr

            assert equal ($busy.stdout | from json | get status) busy

            touch $release

            let completed = job recv --timeout 10sec

            assert equal $completed.exit_code 0 $completed.stderr

            let link = $root | path join linked

            ^ln -s $path $link

            let rejected = try {
                maintain $link 100 7 --apply --now $now

                false
            } catch {
                true
            }

            assert $rejected 'accepted a symlink database'
        } catch {|failure|
            try { job kill $writer } catch { null } | ignore

            error make $failure
        }

        let paged = $root | path join 'paged metrics?.db'

        execute $paged "CREATE TABLE metrics (id INTEGER PRIMARY KEY, event_kind INTEGER, event_ts INTEGER, event_json TEXT);"

        let data = {now: $now} | format pattern "WITH RECURSIVE seq(id) AS (SELECT 1 UNION ALL SELECT id+1 FROM seq WHERE id < 71)
          INSERT INTO metrics SELECT id, 5, {now}, 'abc' FROM seq;"

        execute $paged $data

        assert equal (maintain $paged 10000 7 --now $now | get candidates) 0

        assert equal (maintain $paged 210 7 --now $now | get candidates) 1

        assert equal (maintain $paged 210 7 --apply --now $now | get deleted) 1

        assert equal (rows $paged 'SELECT min(id) AS id FROM metrics' | first | get id) 2

        let chunks = $root | path join chunks.db

        execute $chunks "CREATE TABLE metrics (id INTEGER PRIMARY KEY, event_kind INTEGER, event_ts INTEGER, event_json TEXT);"

        let data = {
            old: ($now - 8 * 86400)
            now: $now
        } | format pattern "WITH RECURSIVE seq(id) AS (SELECT 1 UNION ALL SELECT id+1 FROM seq WHERE id < 130)
          INSERT INTO metrics SELECT id, 5, {old}, 'old' FROM seq;
          INSERT INTO metrics VALUES (131, 9, {now}, 'preserved');"

        execute $chunks $data

        assert equal (maintain $chunks 100 7 --apply --now $now | get deleted) 130

        assert equal (rows $chunks 'SELECT id FROM metrics' | get id) [131]
    } catch {|failure|
        rm --recursive --force $root

        error make $failure
    }

    rm --recursive --force $root

    print 'Git AI retention preserves attribution, usage, unknown events, and live SQLite writers'
}
