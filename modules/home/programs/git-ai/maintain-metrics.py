import argparse
import json
import shutil
import sqlite3
import time
from pathlib import Path


def allocated_bytes(path):
    return sum(
        p.stat().st_blocks * 512 for p in (path, Path(str(path) + "-wal")) if p.exists()
    )


def maintain(path, max_bytes, days, apply=False, now=None):
    if max_bytes <= 0 or days <= 0:
        raise ValueError("retention limits must be positive")
    if path.is_symlink():
        raise ValueError("metrics database must not be a symlink")
    if not path.exists():
        return {"status": "absent", "deleted": 0}
    cutoff = int(time.time() if now is None else now) - days * 86400
    result = {
        "status": "within-limit",
        "deleted": 0,
        "before_bytes": allocated_bytes(path),
    }
    connection = sqlite3.connect(
        path.as_uri() + ("?mode=rw" if apply else "?mode=ro"), uri=True, timeout=1
    )
    try:
        columns = {row[1] for row in connection.execute("PRAGMA table_info(metrics)")}
        if not {"id", "event_kind", "event_ts", "event_json"} <= columns:
            raise ValueError("unsupported Git AI metrics schema")
        used, boundary = 0, -1
        rows = connection.execute(
            "SELECT id, length(CAST(event_json AS BLOB)) FROM metrics "
            "WHERE event_kind IN (5, 6) AND event_ts >= ? ORDER BY id DESC",
            (cutoff,),
        )
        for identifier, size in rows:
            used += size
            if used > max_bytes:
                boundary = identifier
                break
        rows.close()
        predicate = "event_kind IN (5, 6) AND event_ts IS NOT NULL AND (event_ts < ? OR id <= ?)"
        parameters = (cutoff, boundary)
        candidates = connection.execute(
            f"SELECT count(*) FROM metrics WHERE {predicate}", parameters
        ).fetchone()[0]
        result.update(
            candidates=candidates,
            max_session_bytes=max_bytes,
            max_session_age_days=days,
        )
        if not apply:
            result["status"] = "would-prune" if candidates else "within-limit"
            return result
        while True:
            with connection:
                deleted = connection.execute(
                    f"DELETE FROM metrics WHERE id IN (SELECT id FROM metrics WHERE {predicate} LIMIT 64)",
                    parameters,
                ).rowcount
            result["deleted"] += deleted
            if connection.execute("PRAGMA wal_checkpoint(TRUNCATE)").fetchone()[0]:
                result["status"] = "busy"
                break
            if not deleted:
                break
        if result["status"] != "busy":
            page_size = connection.execute("PRAGMA page_size").fetchone()[0]
            pages = connection.execute("PRAGMA page_count").fetchone()[0]
            free_pages = connection.execute("PRAGMA freelist_count").fetchone()[0]
            if free_pages > pages // 4:
                # VACUUM needs space for the compact copy and its write-ahead log.
                required = (pages - free_pages) * page_size * 3 + 256 * 1024 * 1024
                if shutil.disk_usage(path.parent).free < required:
                    result["status"] = "compaction-needs-space"
                else:
                    connection.execute("VACUUM")
                    connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
                    result["status"] = "compacted"
            elif result["deleted"]:
                result["status"] = "pruned"
    finally:
        connection.close()
    result["after_bytes"] = allocated_bytes(path)
    return result


def main():
    parser = argparse.ArgumentParser(
        description="Bound duplicated Git AI session metrics; preserve attribution and usage records"
    )
    parser.add_argument(
        "--database", type=Path, default=Path.home() / ".git-ai/internal/metrics-db"
    )
    parser.add_argument("--max-session-bytes", type=int, default=512 * 1024 * 1024)
    parser.add_argument("--max-session-age-days", type=int, default=7)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    try:
        result = maintain(
            args.database.absolute(),
            args.max_session_bytes,
            args.max_session_age_days,
            args.apply,
        )
    except sqlite3.OperationalError as error:
        if "locked" not in str(error) and "busy" not in str(error):
            raise
        result = {"status": "busy", "error": str(error)}
    print(json.dumps(result))


if __name__ == "__main__":
    main()
