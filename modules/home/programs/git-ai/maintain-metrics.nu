def sqlite-output [path: path, sql: string, apply: bool] {
    let mode = if $apply { 'rw' } else { 'ro' }
    let uri = $'file:($path | url encode --all)?mode=($mode)'
    let result = ^sqlite3 -bail -batch -json -cmd '.timeout 1000' $uri $sql | complete
    if $result.exit_code != 0 { error make {msg: $result.stderr} }
    $result.stdout
}

def query [path: path, sql: string, apply: bool] {
    let output = sqlite-output $path $sql $apply
    if ($output | str trim | is-empty) {
        []
    } else {
        $output | from json
    }
}

def allocated-bytes [path: path] {
    [
        $path
        ($path + '-wal')
    ] | each {|file|
        if ($file | path exists) {
            let result = ^stat --format=%b $file | complete
            if $result.exit_code != 0 { error make {msg: $result.stderr} }
            ($result.stdout | str trim | into int) * 512
        } else { 0 }
    } | math sum
}

export def maintain [
    database: path
    max_bytes: int
    days: int
    --apply
    --now: int
] {
    if $max_bytes <= 0 or $days <= 0 { error make {msg: 'retention limits must be positive'} }
    let path = $database | path expand --no-symlink
    if ($path | path type) == symlink { error make {msg: 'metrics database must not be a symlink'} }
    if not ($path | path exists) { return {status: absent, deleted: 0} }
    let current = $now | default (date now | into int | $in // 1_000_000_000)
    let cutoff = $current - $days * 86400
    mut result = {
        status: within-limit
        deleted: 0
        before_bytes: (allocated-bytes $path)
    }
    let columns = query $path 'PRAGMA table_info(metrics)' $apply | get --optional name | default []
    if not ([id event_kind event_ts event_json] | all {|name| $name in $columns}) {
        error make {msg: 'unsupported Git AI metrics schema'}
    }
    mut used = 0
    mut boundary = -1
    mut cursor = ''
    loop {
        let sql = {cutoff: $cutoff, cursor: $cursor} | format pattern 'SELECT id, length(CAST(event_json AS BLOB)) AS size
          FROM metrics WHERE event_kind IN (5, 6) AND event_ts >= {cutoff} {cursor} ORDER BY id DESC LIMIT 64'
        let recent = query $path $sql $apply
        if ($recent | is-empty) { break }
        for row in $recent {
            $used += $row.size
            if $used > $max_bytes {
                $boundary = $row.id
                break
            }
        }
        if $boundary != -1 { break }
        $cursor = $'AND id < ($recent | last | get id)'
    }
    let predicate = {cutoff: $cutoff, boundary: $boundary} | format pattern 'event_kind IN (5, 6) AND event_ts IS NOT NULL AND (event_ts < {cutoff} OR id <= {boundary})'
    let candidates = (query
        $path
        ('SELECT count(*) AS count FROM metrics WHERE ' + $predicate)
        $apply
    ) | first | get count
    $result = $result | merge {candidates: $candidates, max_session_bytes: $max_bytes, max_session_age_days: $days}
    if not $apply {
        return (
            $result
            | update status (if $candidates > 0 { 'would-prune' } else { 'within-limit' })
        )
    }
    loop {
        let sql = {predicate: $predicate} | format pattern 'BEGIN;
          DELETE FROM metrics WHERE id IN (SELECT id FROM metrics WHERE {predicate} LIMIT 64);
          SELECT changes() AS deleted;
          COMMIT;
          PRAGMA wal_checkpoint(TRUNCATE);'
        let batch = sqlite-output $path $sql true
        | lines
        | each { from json }
        | flatten
        $result.deleted += $batch.0.deleted
        if $batch.1.busy != 0 {
            $result.status = 'busy'
            break
        }
        if $batch.0.deleted == 0 { break }
    }
    if $result.status != busy {
        let page_size = query $path 'PRAGMA page_size' true | first | get page_size
        let pages = query $path 'PRAGMA page_count' true | first | get page_count
        let free_pages = query $path 'PRAGMA freelist_count' true | first | get freelist_count
        if $free_pages > $pages // 4 {
            let required = ($pages - $free_pages) * $page_size * 3 + 256 * 1024 * 1024
            let space = ^df --block-size=1 --output=avail ($path | path dirname) | complete
            if $space.exit_code != 0 { error make {msg: $space.stderr} }
            let available = $space.stdout | lines | last | str trim | into int
            if $available < $required {
                $result.status = 'compaction-needs-space'
            } else {
                (query
                    $path
                    'VACUUM; PRAGMA wal_checkpoint(TRUNCATE)'
                    true
                ) | ignore
                $result.status = 'compacted'
            }
        } else if $result.deleted > 0 { $result.status = 'pruned' }
    }
    $result | upsert after_bytes (allocated-bytes $path)
}

def main [
    --database: path
    --max-session-bytes: int = 536870912
    --max-session-age-days: int = 7
    --apply
] {
    let path = $database | default ($env.HOME | path join .git-ai internal metrics-db)
    let result = try {
        maintain $path $max_session_bytes $max_session_age_days --apply=$apply
    } catch {|failure|
        if $failure.msg =~ '(?i)locked|busy' { {status: busy, error: $failure.msg} } else { error make $failure }
    }
    $result | to json | print
}
