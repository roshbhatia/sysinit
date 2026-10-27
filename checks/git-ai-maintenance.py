import importlib.util
import sqlite3
import sys
import tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location("maintenance", sys.argv[1])
maintenance = importlib.util.module_from_spec(spec)
spec.loader.exec_module(maintenance)

with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / "metrics-db"
    writer = sqlite3.connect(path)
    writer.execute("PRAGMA journal_mode=WAL")
    writer.execute(
        "CREATE TABLE metrics (id INTEGER PRIMARY KEY, event_kind INTEGER, event_ts INTEGER, event_json TEXT)"
    )
    writer.execute("CREATE TABLE unrelated (value TEXT)")
    writer.execute("INSERT INTO unrelated VALUES ('preserved')")
    now = 2_000_000_000
    rows = [
        (i, kind, now, "preserved") for i, kind in enumerate([1, 2, 3, 4, 7, 8, 9], 1)
    ]
    rows += [(10, 5, now - 8 * 86400, "old" * 400_000)]
    rows += [(11, 5, now, "older recent" * 100_000), (12, 6, now, "newest")]
    rows += [(13, 5, None, "unknown time"), (14, 100, now, "unknown kind")]
    writer.executemany("INSERT INTO metrics VALUES (?, ?, ?, ?)", rows)
    writer.commit()
    before = writer.execute("SELECT * FROM metrics ORDER BY id").fetchall()
    result = maintenance.maintain(path, 100, 7, now=now)
    assert result["status"] == "would-prune" and result["candidates"] == 2, result
    assert writer.execute("SELECT * FROM metrics ORDER BY id").fetchall() == before
    result = maintenance.maintain(path, 100, 7, apply=True, now=now)
    assert result["deleted"] == 2 and result["status"] == "compacted", result
    assert result["after_bytes"] < result["before_bytes"], result
    expected = [row for row in rows if row[0] not in (10, 11)]
    assert writer.execute("SELECT * FROM metrics ORDER BY id").fetchall() == expected
    assert writer.execute("SELECT * FROM unrelated").fetchall() == [("preserved",)]
    writer.execute(
        "INSERT INTO metrics VALUES (15, 9, ?, 'writer stays usable')", (now,)
    )
    writer.commit()
    assert (
        maintenance.maintain(path, 100, 7, apply=True, now=now)["status"]
        == "within-limit"
    )
    writer.execute("BEGIN IMMEDIATE")
    writer.execute("INSERT INTO metrics VALUES (16, 5, ?, 'uncommitted')", (now,))
    try:
        maintenance.maintain(path, 100, 7, apply=True, now=now)
    except sqlite3.OperationalError as error:
        assert "locked" in str(error), error
    else:
        raise AssertionError("competing writer was not respected")
    writer.rollback()
    writer.close()
    link = Path(directory) / "linked"
    link.symlink_to(path)
    try:
        maintenance.maintain(link, 100, 7, apply=True, now=now)
    except ValueError:
        pass
    else:
        raise AssertionError("accepted a symlink database")

print(
    "Git AI retention preserves attribution, usage, unknown events, and live SQLite writers"
)
