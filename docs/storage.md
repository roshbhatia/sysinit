# Storage and attribution diagnostics

The managed Nushell modules return structured values that can be filtered, sorted,
and exported with ordinary pipelines. Commands run in the current directory.

```nu
storage free
storage usage ~/.cache --depth 2 --top 15
storage caches | select name before_bytes max_bytes status
storage nix-roots | where root =~ 'result|\.sysinit'

attribution status | select repository trace2 repository_status
attribution stats HEAD
attribution diff HEAD~1..HEAD
attribution notes --commit HEAD | select summary session anchor
attribution sessions --commit HEAD
attribution storage
```

Use `changes` for review and `traces --all --session <id>` for the originating
conversation. The attribution helpers read Git AI or its Changes provider; they
do not replace either tool or modify review notes. Git AI records authorship in
`refs/notes/ai`; shared harness hooks checkpoint edits and Git Trace2 feeds its
background daemon. Unsupported harness hooks do not acquire attribution merely
because a client is installed.

`storage usage` measures allocated blocks, stays on one filesystem, and does not
follow symlinks. Parent rows include their descendants; do not sum overlapping
rows. Permission errors fail the command. APFS clones, sparse VM disks, and
hardlinks mean a directory size is not necessarily its reclaimable size. APFS
volumes can share a free-space pool; do not sum their free-space figures.

## Managed retention

| Owner | Policy | Limit |
| --- | --- | --- |
| Git AI | Hourly duplicated session/OTel event cleanup, followed by SQLite compaction when needed | 7 days and 512 MiB of event JSON, whichever retains less |
| Darwin cache maintenance | Hourly native Go, Lima download, and uv cleanup | Triggers at 4 GiB, 4 GiB, and 2 GiB respectively |
| Docker in Colima | Native BuildKit garbage collection | 4 GB maximum build cache, with 1 GB reserved |
| Colima | Daily guest filesystem trim | Returns unused guest blocks to the host |
| Determinate Nix | Existing automatic garbage collector, with automatic store deduplication | Collector targets free space; referenced paths remain retained |
| Darwin service logs | Existing logrotate job, including Git AI logs | Check every five minutes, rotate above 10 MB, keep three archives |

These are periodic retention policies, not filesystem quotas. Git AI's payload
budget excludes database overhead, attribution/checkpoint/token records, and
events whose metadata is unknown. Cleanup defers on SQLite writer contention.
Original harness transcripts and Git notes remain intact. A Git AI schema change
that removes required fields fails maintenance instead of guessing what to delete.

Docker cannot reclaim image data still referenced by tagged images or containers.
Build activity can temporarily exceed its cache ceiling. Colima's generated daemon
policy takes effect when the VM next starts; do not restart an active workload to
apply it. A smaller virtual disk ceiling does not reclaim allocated guest blocks.

Nix build-result symlinks retain their entire dependency closure. Reuse a task's
output link and remove its temporary check/package links after verification.
Keep a prepared deployment rooted through activation. Inspect other tasks' roots
before cleanup; do not schedule indiscriminate age-based deletion of result links.
The Darwin generation pruner runs at load and every five minutes. It does not use
`WatchPaths` on system symlinks: macOS retains open directory handles on their old
targets, and Nix consequently treats those old system closures as live roots.

`storage caches` previews native cache actions. `storage caches --apply` explicitly
applies them. `git-ai-maintain` previews duplicated-event retention;
`git-ai-maintain --apply` applies it. Native maintenance may retain data or defer
when busy; inspect the reported status rather than treating a threshold as a quota.

Application data, VM disks, tool installations, worktrees, and agent transcripts
need their owning application's lifecycle. They are not generic disposable caches.

References: [Git AI metrics storage](https://github.com/git-ai-project/git-ai/blob/f67fe0d732dfebf6bc229ad7c784e3a8a2d42a66/src/metrics/db.rs),
[Docker garbage collection](https://docs.docker.com/build/cache/garbage-collection/),
[Determinate managed collection](https://docs.determinate.systems/determinate-nix/determinate-nixd/#managed-garbage-collection).
