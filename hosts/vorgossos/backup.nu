def main [] {
    let primary = '/mnt/backup/restic-vorgossos'

    let mirror = '/mnt/backup2/restic-vorgossos'

    let flags = [--repo $primary --insecure-no-password]

    let excludes = [
        '/storage/services/slskd/data/downloads'
        '/storage/services/slskd/data/incomplete'
        '/storage/services/qbittorrent/downloads'
        '/storage/services/lidarr/music'
        '/storage/services/podgrab/assets'
        '/storage/services/romm/library'
        '/storage/services/.cull'
        '/storage/services/*/cache'
        '/storage/services/*/Cache'
        '/storage/services/*/transcodes'
        '/storage/services/*/.git/objects/pack/tmp_*'
    ] | each {|path| [--exclude $path] } | flatten

    ^mountpoint --quiet /mnt/backup

    ^findmnt --mountpoint /storage --types zfs

    ^findmnt --mountpoint /storage/services --types zfs

    ^restic ...$flags backup /storage /storage/services --tag automated --one-file-system ...$excludes

    ^restic ...$flags forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune

    let mounted = (^mountpoint --quiet /mnt/backup2 | complete)

    if $mounted.exit_code == 0 {
        ^restic --repo $mirror --insecure-no-password copy --from-repo $primary --from-insecure-no-password
    } else {
        print --stderr 'Secondary backup disk is not mounted.'
    }

    ^restic ...$flags check
}
