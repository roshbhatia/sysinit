CREATE TABLE records (
    kind TEXT NOT NULL,
    id TEXT NOT NULL,
    schema_version INTEGER NOT NULL,
    resource_version INTEGER NOT NULL,
    payload BLOB NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    PRIMARY KEY (kind, id)
);

CREATE TABLE events (
    cursor INTEGER PRIMARY KEY AUTOINCREMENT,
    schema_version INTEGER NOT NULL,
    occurred_at TEXT NOT NULL,
    aggregate_kind TEXT NOT NULL,
    aggregate_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload BLOB NOT NULL,
    metadata BLOB NOT NULL
);

CREATE INDEX events_aggregate_cursor
    ON events (aggregate_kind, aggregate_id, cursor);

CREATE TABLE schema_migrations (
    version INTEGER PRIMARY KEY,
    applied_at TEXT NOT NULL
);
