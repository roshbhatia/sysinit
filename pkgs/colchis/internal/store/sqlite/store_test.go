package sqlite

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"golang.org/x/sys/unix"
)

func TestOpenRejectsNewerSchema(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "colchis.db")
	database, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	if _, err := database.Exec("PRAGMA user_version = 4"); err != nil {
		t.Fatalf("setting user_version returned %v", err)
	}
	if _, err := database.Exec("PRAGMA journal_mode = DELETE"); err != nil {
		t.Fatalf("setting journal_mode returned %v", err)
	}
	if err := database.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	before, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("ReadFile() before Open() returned %v", err)
	}

	_, err = Open(context.Background(), path)
	if !domain.IsErrorCode(err, domain.ErrorCodeUnsupportedVersion) {
		t.Fatalf("Open() error = %v", err)
	}
	after, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("ReadFile() after Open() returned %v", err)
	}
	if !bytes.Equal(after, before) {
		t.Fatal("Open() changed a newer database")
	}
}

func TestOpenMigratesSchemaVersionOneToCurrent(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "colchis.db")
	database, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	for _, statement := range splitStatements(initialSchema) {
		if _, err := database.Exec(statement); err != nil {
			database.Close()
			t.Fatalf("applying initial schema returned %v", err)
		}
	}
	if _, err := database.Exec(
		"INSERT INTO schema_migrations(version, applied_at) VALUES(1, ?)", time.Now().UTC(),
	); err != nil {
		database.Close()
		t.Fatalf("recording schema version one returned %v", err)
	}
	if _, err := database.Exec("PRAGMA user_version = 1"); err != nil {
		database.Close()
		t.Fatalf("setting user_version returned %v", err)
	}
	if err := database.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	restrictFixtureState(t, path)

	store, err := Open(context.Background(), path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	var version int
	var migrationCount int
	if err := store.db.QueryRow("PRAGMA user_version").Scan(&version); err != nil {
		t.Fatalf("reading user_version returned %v", err)
	}
	if err := store.db.QueryRow("SELECT COUNT(*) FROM schema_migrations WHERE version IN (2, 3)").Scan(
		&migrationCount,
	); err != nil {
		t.Fatalf("reading migration history returned %v", err)
	}
	if version != currentSchemaVersion || migrationCount != 2 {
		t.Fatalf("migration result = version %d, records %d", version, migrationCount)
	}
}

func TestOpenMigratesSchemaVersionTwoToCurrent(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "colchis.db")
	database, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	for _, statement := range splitStatements(initialSchema) {
		if _, err := database.Exec(statement); err != nil {
			database.Close()
			t.Fatalf("applying initial schema returned %v", err)
		}
	}
	for _, version := range []int{1, 2} {
		if _, err := database.Exec(
			"INSERT INTO schema_migrations(version, applied_at) VALUES(?, ?)", version, time.Now().UTC(),
		); err != nil {
			database.Close()
			t.Fatalf("recording schema version %d returned %v", version, err)
		}
	}
	if _, err := database.Exec("PRAGMA user_version = 2"); err != nil {
		database.Close()
		t.Fatalf("setting user_version returned %v", err)
	}
	if err := database.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	restrictFixtureState(t, path)

	store, err := Open(context.Background(), path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	var version int
	var migrationCount int
	if err := store.db.QueryRow("PRAGMA user_version").Scan(&version); err != nil {
		t.Fatalf("reading user_version returned %v", err)
	}
	if err := store.db.QueryRow("SELECT COUNT(*) FROM schema_migrations WHERE version = 3").Scan(
		&migrationCount,
	); err != nil {
		t.Fatalf("reading migration history returned %v", err)
	}
	if version != currentSchemaVersion || migrationCount != 1 {
		t.Fatalf("migration result = version %d, records %d", version, migrationCount)
	}
}

func TestConnectionDataSourceSetsStartupBusyTimeout(t *testing.T) {
	t.Parallel()

	rawPath := filepath.Join(t.TempDir(), "state with space", "colchis.db")
	configured, err := connectionDataSource(rawPath)
	if err != nil {
		t.Fatalf("connectionDataSource() returned %v", err)
	}
	location, err := url.Parse(configured)
	if err != nil {
		t.Fatalf("url.Parse() returned %v", err)
	}
	if location.Path != rawPath || location.Query().Get("_busy_timeout") != "5000" {
		t.Fatalf("configured data source = %q", configured)
	}

	configured, err = connectionDataSource("file:///tmp/colchis.db?immutable=1&mode=ro")
	if err != nil {
		t.Fatalf("read-only connectionDataSource() returned %v", err)
	}
	location, err = url.Parse(configured)
	if err != nil {
		t.Fatalf("read-only url.Parse() returned %v", err)
	}
	query := location.Query()
	if query.Get("_busy_timeout") != "5000" || query.Get("immutable") != "1" || query.Get("mode") != "ro" {
		t.Fatalf("read-only configured data source = %q", configured)
	}
}

func TestOpenRestrictsSharedStateDirectory(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	if err := os.Chmod(directory, 0o755); err != nil {
		t.Fatalf("Chmod() returned %v", err)
	}
	store, err := Open(context.Background(), filepath.Join(directory, "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	info, err := os.Stat(directory)
	if err != nil {
		t.Fatalf("Stat() returned %v", err)
	}
	if info.Mode().Perm() != 0o700 {
		t.Fatalf("state directory mode = %o", info.Mode().Perm())
	}
}

func TestOpenRestrictsDatabaseFile(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(context.Background(), path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	info, err := os.Stat(path)
	if err != nil {
		t.Fatalf("Stat() returned %v", err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("database mode = %o", info.Mode().Perm())
	}
}

func TestOpenRejectsReplaceableStateAncestor(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	unsafeAncestor := filepath.Join(root, "unsafe")
	if err := os.Mkdir(unsafeAncestor, 0o777); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	if err := os.Chmod(unsafeAncestor, 0o777); err != nil {
		t.Fatalf("Chmod() returned %v", err)
	}
	path := filepath.Join(unsafeAncestor, "state", "colchis.db")
	_, err := Open(context.Background(), path)
	if !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("Open() error = %v", err)
	}
	if _, err := os.Stat(path); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("database stat error = %v", err)
	}
}

func TestOpenReadOnlyRejectsSharedDirectoryBeforeSpecialFile(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	if err := os.Chmod(directory, 0o755); err != nil {
		t.Fatalf("Chmod() returned %v", err)
	}
	path := filepath.Join(directory, "colchis.db")
	if err := unix.Mkfifo(path, 0o600); err != nil {
		t.Fatalf("Mkfifo() returned %v", err)
	}
	_, err := OpenReadOnly(context.Background(), path)
	if !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("OpenReadOnly() error = %v", err)
	}
}

func TestReadOnlySnapshotRecoversHotRollbackJournal(t *testing.T) {
	if os.Getenv("COLCHIS_HOT_JOURNAL_PATH") != "" {
		runHotJournalWriter(t)
		return
	}

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "source.db")
	database, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	if _, err := database.Exec(`
		PRAGMA journal_mode=DELETE;
		CREATE TABLE items(id INTEGER PRIMARY KEY, value INTEGER NOT NULL, payload BLOB NOT NULL);
		WITH RECURSIVE values_list(id) AS (
			SELECT 1 UNION ALL SELECT id + 1 FROM values_list WHERE id < 200
		) INSERT INTO items SELECT id, 0, zeroblob(32768) FROM values_list;
	`); err != nil {
		t.Fatalf("creating fixture returned %v", err)
	}
	if err := database.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	restrictFixtureState(t, path)
	readyPath := filepath.Join(t.TempDir(), "ready")
	command := exec.Command(os.Args[0], "-test.run=TestReadOnlySnapshotRecoversHotRollbackJournal$")
	command.Env = append(os.Environ(),
		"COLCHIS_HOT_JOURNAL_PATH="+path,
		"COLCHIS_HOT_JOURNAL_READY="+readyPath,
	)
	if err := command.Start(); err != nil {
		t.Fatalf("Start() returned %v", err)
	}
	deadline := time.Now().Add(30 * time.Second)
	for {
		if _, err := os.Stat(readyPath); err == nil {
			break
		}
		if time.Now().After(deadline) {
			command.Process.Kill()
			command.Wait()
			t.Fatal("hot journal writer did not become ready")
		}
		time.Sleep(10 * time.Millisecond)
	}
	if err := command.Process.Kill(); err != nil {
		t.Fatalf("Kill() returned %v", err)
	}
	if err := command.Wait(); err == nil {
		t.Fatal("hot journal writer exited without termination")
	}
	journal, err := os.Stat(path + "-journal")
	if err != nil || journal.Size() == 0 {
		t.Fatalf("hot journal stat = %#v, error = %v", journal, err)
	}
	snapshot, err := OpenReadOnlyIn(ctx, path, t.TempDir())
	if err != nil {
		t.Fatalf("OpenReadOnlyIn() returned %v", err)
	}
	defer snapshot.Close()
	if snapshot.readOnlyCleanup == "" {
		t.Fatal("OpenReadOnlyIn() did not isolate the hot rollback journal")
	}
	var changed int
	if err := snapshot.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM items WHERE value != 0").Scan(&changed); err != nil {
		t.Fatalf("counting recovered rows returned %v", err)
	}
	if changed != 0 {
		t.Fatalf("recovered changed rows = %d", changed)
	}
}

func runHotJournalWriter(t *testing.T) {
	path := os.Getenv("COLCHIS_HOT_JOURNAL_PATH")
	database, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	database.SetMaxOpenConns(1)
	connection, err := database.Conn(context.Background())
	if err != nil {
		t.Fatalf("Conn() returned %v", err)
	}
	if _, err := connection.ExecContext(context.Background(), "PRAGMA cache_size=5"); err != nil {
		t.Fatalf("setting cache size returned %v", err)
	}
	if _, err := connection.ExecContext(context.Background(), "BEGIN EXCLUSIVE"); err != nil {
		t.Fatalf("beginning transaction returned %v", err)
	}
	if _, err := connection.ExecContext(
		context.Background(), "UPDATE items SET value = 1, payload = randomblob(32768)",
	); err != nil {
		t.Fatalf("updating fixture returned %v", err)
	}
	if err := os.WriteFile(os.Getenv("COLCHIS_HOT_JOURNAL_READY"), nil, 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	select {}
}

func TestOpenRejectsNewerSchemaInWriteAheadLogWithoutChangingFiles(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "colchis.db")
	database, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	defer database.Close()
	if _, err := database.Exec("PRAGMA journal_mode = WAL"); err != nil {
		t.Fatalf("setting journal_mode returned %v", err)
	}
	if _, err := database.Exec("PRAGMA user_version = 1"); err != nil {
		t.Fatalf("setting initial user_version returned %v", err)
	}
	if _, err := database.Exec("PRAGMA wal_checkpoint(TRUNCATE)"); err != nil {
		t.Fatalf("checkpointing initial version returned %v", err)
	}
	if _, err := database.Exec("PRAGMA user_version = 4"); err != nil {
		t.Fatalf("setting newer user_version returned %v", err)
	}
	restrictFixtureState(t, path, path+"-wal")

	paths := []string{path, path + "-wal"}
	before := make(map[string][]byte, len(paths))
	for _, filePath := range paths {
		contents, err := os.ReadFile(filePath)
		if err != nil {
			t.Fatalf("ReadFile(%q) before Open() returned %v", filePath, err)
		}
		before[filePath] = contents
	}

	_, err = Open(context.Background(), path)
	if !domain.IsErrorCode(err, domain.ErrorCodeUnsupportedVersion) {
		t.Fatalf("Open() error = %v", err)
	}
	for _, filePath := range paths {
		after, err := os.ReadFile(filePath)
		if err != nil {
			t.Fatalf("ReadFile(%q) after Open() returned %v", filePath, err)
		}
		if !bytes.Equal(after, before[filePath]) {
			t.Fatalf("Open() changed %q", filePath)
		}
	}
}

func TestOpenRejectsDatabaseSymlinkWithoutChangingTarget(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	target := filepath.Join(root, "outside.db")
	database, err := sql.Open("sqlite", target)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	if _, err := database.Exec("PRAGMA user_version = 2"); err != nil {
		t.Fatalf("setting user_version returned %v", err)
	}
	if err := database.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	before, err := os.ReadFile(target)
	if err != nil {
		t.Fatalf("ReadFile() before Open() returned %v", err)
	}

	stateDirectory := filepath.Join(root, "state")
	if err := os.Mkdir(stateDirectory, 0o700); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	path := filepath.Join(stateDirectory, "colchis.db")
	if err := os.Symlink(target, path); err != nil {
		t.Fatalf("Symlink() returned %v", err)
	}

	_, err = Open(context.Background(), path)
	if !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("Open() error = %v", err)
	}
	after, err := os.ReadFile(target)
	if err != nil {
		t.Fatalf("ReadFile() after Open() returned %v", err)
	}
	if !bytes.Equal(after, before) {
		t.Fatal("Open() changed the symbolic link target")
	}
}

func TestOpenRejectsStateDirectorySymlinkWithoutCreatingDatabase(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	target := filepath.Join(root, "outside")
	if err := os.Mkdir(target, 0o700); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	stateDirectory := filepath.Join(root, "state")
	if err := os.Symlink(target, stateDirectory); err != nil {
		t.Fatalf("Symlink() returned %v", err)
	}

	_, err := Open(context.Background(), filepath.Join(stateDirectory, "colchis.db"))
	if !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("Open() error = %v", err)
	}
	if _, err := os.Stat(filepath.Join(target, "colchis.db")); !os.IsNotExist(err) {
		t.Fatalf("outside database stat error = %v", err)
	}
}

func TestOpenCreatesOwnerOnlyMaterializationLock(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(context.Background(), path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	lockPath := filepath.Join(filepath.Dir(path), materializationLockName)
	info, err := os.Lstat(lockPath)
	if err != nil {
		t.Fatalf("Lstat() returned %v", err)
	}
	if !info.Mode().IsRegular() || info.Mode().Perm() != 0o600 {
		t.Fatalf("materialization lock mode = %v", info.Mode())
	}
}

func TestOpenRejectsMaterializationLockSymlink(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	target := filepath.Join(directory, "target")
	if err := os.WriteFile(target, nil, 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	lockPath := filepath.Join(directory, materializationLockName)
	if err := os.Symlink(target, lockPath); err != nil {
		t.Fatalf("Symlink() returned %v", err)
	}
	_, err := Open(context.Background(), filepath.Join(directory, "colchis.db"))
	if err == nil {
		t.Fatal("Open() accepted a symbolic materialization lock")
	}
}

func TestMaterializationLockMigrationDrainsLegacyExports(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "colchis.db")
	database, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	if _, err := database.Exec("PRAGMA user_version = 1"); err != nil {
		t.Fatalf("setting user_version returned %v", err)
	}
	if err := database.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	restrictFixtureState(t, path)
	legacyLease, err := acquireSourceMaterializationLock(path)
	if err != nil {
		t.Fatalf("acquireSourceMaterializationLock() returned %v", err)
	}
	if err := ensureMaterializationLock(path); !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
		legacyLease.Close()
		t.Fatalf("ensureMaterializationLock() error = %v", err)
	}
	if _, err := os.Lstat(filepath.Join(filepath.Dir(path), materializationLockName)); !errors.Is(
		err, os.ErrNotExist,
	) {
		legacyLease.Close()
		t.Fatalf("materialization lock stat error = %v", err)
	}
	if err := legacyLease.Close(); err != nil {
		t.Fatalf("legacy lease Close() returned %v", err)
	}
	if err := ensureMaterializationLock(path); err != nil {
		t.Fatalf("ensureMaterializationLock() returned %v", err)
	}
}

func TestBackupRejectsBusyWriteAheadLogCheckpoint(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	if _, err := store.AppendEvent(ctx, storeTestEvent("before")); err != nil {
		t.Fatalf("AppendEvent() before checkpoint returned %v", err)
	}
	if _, err := store.db.ExecContext(ctx, "PRAGMA wal_checkpoint(TRUNCATE)"); err != nil {
		t.Fatalf("initial checkpoint returned %v", err)
	}

	reader, err := sql.Open("sqlite", "file:"+path+"?mode=ro")
	if err != nil {
		t.Fatalf("opening reader returned %v", err)
	}
	defer reader.Close()
	transaction, err := reader.BeginTx(ctx, &sql.TxOptions{ReadOnly: true})
	if err != nil {
		t.Fatalf("BeginTx() returned %v", err)
	}
	defer transaction.Rollback()
	var count int
	if err := transaction.QueryRowContext(ctx, "SELECT COUNT(*) FROM events").Scan(&count); err != nil {
		t.Fatalf("reading initial snapshot returned %v", err)
	}
	if _, err := store.AppendEvent(ctx, storeTestEvent("after")); err != nil {
		t.Fatalf("AppendEvent() after checkpoint returned %v", err)
	}
	if _, err := store.db.ExecContext(ctx, "PRAGMA busy_timeout = 1"); err != nil {
		t.Fatalf("setting busy timeout returned %v", err)
	}

	if err := store.backup(ctx); !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("backup() error = %v", err)
	}
	if _, err := os.Stat(path + ".backup"); !os.IsNotExist(err) {
		t.Fatalf("backup stat error = %v", err)
	}
}

func TestBackupPublishesVerifiedCopy(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if _, err := store.AppendEvent(ctx, storeTestEvent("backup")); err != nil {
		t.Fatalf("AppendEvent() returned %v", err)
	}
	if err := store.backup(ctx); err != nil {
		t.Fatalf("backup() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	backup, err := OpenReadOnly(ctx, path+".backup")
	if err != nil {
		t.Fatalf("OpenReadOnly() returned %v", err)
	}
	defer backup.Close()
	inspection, err := backup.Inspect(ctx)
	if err != nil {
		t.Fatalf("Inspect() returned %v", err)
	}
	if inspection.SchemaVersion != currentSchemaVersion || inspection.LastEventCursor != 1 {
		t.Fatalf("backup inspection = %#v", inspection)
	}
}

func TestOpenBacksUpExistingVersionZeroDatabase(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	database, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	if _, err := database.Exec("CREATE TABLE legacy(value TEXT NOT NULL)"); err != nil {
		t.Fatalf("creating legacy table returned %v", err)
	}
	if err := database.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	backup, err := sql.Open("sqlite", "file:"+path+".backup?mode=ro")
	if err != nil {
		t.Fatalf("opening backup returned %v", err)
	}
	defer backup.Close()
	var tables int
	if err := backup.QueryRowContext(
		ctx, "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = 'legacy'",
	).Scan(&tables); err != nil {
		t.Fatalf("inspecting backup returned %v", err)
	}
	if tables != 1 {
		t.Fatalf("legacy table count = %d", tables)
	}
}

func TestBackupHonorsSnapshotByteBudget(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	store.budgets.MaxSnapshotBytes = 1
	if err := store.backup(ctx); !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
		t.Fatalf("backup() error = %v", err)
	}
	if _, err := os.Stat(store.path + ".backup"); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("backup stat error = %v", err)
	}
}

func TestExportHonorsSnapshotByteBudget(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	store.budgets.MaxSnapshotBytes = 1
	target := filepath.Join(t.TempDir(), "export.db")
	if err := store.ExportTo(ctx, target); !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
		t.Fatalf("ExportTo() error = %v", err)
	}
	if _, err := os.Stat(target); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("export stat error = %v", err)
	}
}

func TestExportsShareMaterializationBudgetAcrossTargets(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	budgets := domain.DefaultBudgets()
	budgets.MaxMaterializedSnapshots = 1
	store, err := OpenWithBudgets(ctx, filepath.Join(t.TempDir(), "colchis.db"), budgets)
	if err != nil {
		t.Fatalf("OpenWithBudgets() returned %v", err)
	}
	path := store.path
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	lease, err := acquireSourceMaterializationLock(path)
	if err != nil {
		t.Fatalf("acquireSourceMaterializationLock() returned %v", err)
	}
	defer lease.Close()
	target := filepath.Join(t.TempDir(), "export.db")
	if err := ExportReadOnly(ctx, path, target); !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
		t.Fatalf("ExportReadOnly() error = %v", err)
	}
}

func TestExportReadOnlyWithActiveWriterSharesMaterializationBudget(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	lease, err := acquireSourceMaterializationLock(path)
	if err != nil {
		t.Fatalf("acquireSourceMaterializationLock() returned %v", err)
	}
	defer lease.Close()
	target := filepath.Join(t.TempDir(), "export.db")
	if err := ExportReadOnly(ctx, path, target); !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
		t.Fatalf("ExportReadOnly() error = %v", err)
	}
}

func TestExportToCleansCrashRemainder(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	targetParent := t.TempDir()
	base := filepath.Join(targetParent, fmt.Sprintf(".colchis-readonly-%d", os.Geteuid()))
	if err := os.MkdirAll(base, 0o700); err != nil {
		t.Fatalf("MkdirAll() returned %v", err)
	}
	stale := filepath.Join(base, "snapshot-crashed-export")
	if err := os.Mkdir(stale, 0o700); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	if err := os.WriteFile(filepath.Join(base, "lease-crashed-export"), nil, 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	if err := store.ExportTo(ctx, filepath.Join(targetParent, "export.db")); err != nil {
		t.Fatalf("ExportTo() returned %v", err)
	}
	if _, err := os.Stat(stale); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("stale export remains: %v", err)
	}
}

func TestInterruptedMigrationRollsBackEveryStatement(t *testing.T) {
	t.Parallel()

	steps := len(splitStatements(initialSchema)) + 4
	for failedStep := 1; failedStep <= steps; failedStep++ {
		failedStep := failedStep
		t.Run(fmt.Sprintf("step-%d", failedStep), func(t *testing.T) {
			t.Parallel()

			ctx := context.Background()
			path := filepath.Join(t.TempDir(), "colchis.db")
			store, err := openDatabase(ctx, path)
			if err != nil {
				t.Fatalf("openDatabase() returned %v", err)
			}
			injected := errors.New("injected migration interruption")
			err = store.migrate(ctx, 0, func(step int) error {
				if step == failedStep {
					return injected
				}
				return nil
			})
			if !errors.Is(err, injected) {
				t.Fatalf("migrate() error = %v", err)
			}
			if err := store.Close(); err != nil {
				t.Fatalf("Close() returned %v", err)
			}

			database, err := sql.Open("sqlite", path)
			if err != nil {
				t.Fatalf("sql.Open() returned %v", err)
			}
			var version int
			if err := database.QueryRow("PRAGMA user_version").Scan(&version); err != nil {
				t.Fatalf("reading user_version returned %v", err)
			}
			var tables int
			if err := database.QueryRow(
				"SELECT COUNT(*) FROM sqlite_schema WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
			).Scan(&tables); err != nil {
				t.Fatalf("counting tables returned %v", err)
			}
			if err := database.Close(); err != nil {
				t.Fatalf("Close() returned %v", err)
			}
			if version != 0 || tables != 0 {
				t.Fatalf("rolled back schema has version %d and %d tables", version, tables)
			}

			recovered, err := Open(ctx, path)
			if err != nil {
				t.Fatalf("Open() after interruption returned %v", err)
			}
			defer recovered.Close()
			inspection, err := recovered.Inspect(ctx)
			if err != nil {
				t.Fatalf("Inspect() returned %v", err)
			}
			if inspection.SchemaVersion != currentSchemaVersion || inspection.Integrity != "ok" {
				t.Fatalf("recovered inspection = %#v", inspection)
			}
		})
	}
}

func TestKilledMigrationRecoversFromJournalAndBackup(t *testing.T) {
	if path := os.Getenv("COLCHIS_KILLED_MIGRATION_PATH"); path != "" {
		runKilledMigration(t, path, os.Getenv("COLCHIS_KILLED_MIGRATION_READY"))
		return
	}

	path := filepath.Join(t.TempDir(), "colchis.db")
	ready := filepath.Join(t.TempDir(), "ready")
	database, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	if _, err := database.Exec("CREATE TABLE legacy(value TEXT NOT NULL)"); err != nil {
		t.Fatalf("creating legacy table returned %v", err)
	}
	if err := database.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	restrictFixtureState(t, path)
	command := exec.Command(os.Args[0], "-test.run=TestKilledMigrationRecoversFromJournalAndBackup$")
	command.Env = append(os.Environ(),
		"COLCHIS_KILLED_MIGRATION_PATH="+path,
		"COLCHIS_KILLED_MIGRATION_READY="+ready,
	)
	if err := command.Start(); err != nil {
		t.Fatalf("Start() returned %v", err)
	}
	deadline := time.Now().Add(5 * time.Second)
	for {
		if _, err := os.Stat(ready); err == nil {
			break
		}
		if time.Now().After(deadline) {
			command.Process.Kill()
			command.Wait()
			t.Fatal("migration helper did not enter its transaction")
		}
		time.Sleep(10 * time.Millisecond)
	}
	if err := command.Process.Kill(); err != nil {
		t.Fatalf("Kill() returned %v", err)
	}
	if err := command.Wait(); err == nil {
		t.Fatal("migration helper exited without termination")
	}
	store, err := Open(context.Background(), path)
	if err != nil {
		t.Fatalf("Open() after termination returned %v", err)
	}
	defer store.Close()
	if err := store.integrityCheck(context.Background()); err != nil {
		t.Fatalf("integrityCheck() returned %v", err)
	}
	backup, err := OpenReadOnly(context.Background(), path+".backup")
	if err != nil {
		t.Fatalf("OpenReadOnly() backup returned %v", err)
	}
	defer backup.Close()
}

func runKilledMigration(t *testing.T, path string, ready string) {
	t.Helper()
	store, err := openDatabase(context.Background(), path)
	if err != nil {
		t.Fatalf("openDatabase() returned %v", err)
	}
	defer store.Close()
	err = store.migrate(context.Background(), 0, func(step int) error {
		if step != 1 {
			return nil
		}
		if err := os.WriteFile(ready, nil, 0o600); err != nil {
			return err
		}
		select {}
	})
	t.Fatalf("migrate() returned %v", err)
}

func TestOpenMigratesAndPersistsEvents(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "state", "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}

	event := domain.EventEnvelope{
		SchemaVersion: domain.CurrentEventSchemaVersion,
		OccurredAt:    time.Unix(10, 0).UTC(),
		Aggregate:     domain.ResourceReference{Kind: "session", ID: "session-83"},
		Type:          "owner.message",
		Payload:       json.RawMessage(`{"text":"continue"}`),
		Metadata:      map[string]string{"source": "owner"},
	}
	appended, err := store.AppendEvent(ctx, event)
	if err != nil {
		t.Fatalf("AppendEvent() returned %v", err)
	}
	if appended.Cursor != 1 {
		t.Fatalf("AppendEvent() cursor = %d", appended.Cursor)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	store, err = Open(ctx, path)
	if err != nil {
		t.Fatalf("second Open() returned %v", err)
	}
	defer store.Close()
	events, err := store.EventsAfter(ctx, 0, 10)
	if err != nil {
		t.Fatalf("EventsAfter() returned %v", err)
	}
	if len(events) != 1 {
		t.Fatalf("EventsAfter() count = %d", len(events))
	}
	if events[0].Type != event.Type || events[0].Metadata["source"] != "owner" {
		t.Fatalf("EventsAfter() event = %#v", events[0])
	}
}

func TestHistoricalEventFixtureReplaysAfterRestart(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	database, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	_, err = database.Exec(
		`INSERT INTO events(
			schema_version, occurred_at, aggregate_kind, aggregate_id, event_type, payload, metadata
		) VALUES(?, ?, ?, ?, ?, ?, ?)`,
		1,
		time.Unix(10, 0).UTC().Format(time.RFC3339Nano),
		"session",
		"session-83",
		"owner.message",
		[]byte(`{"text":"continue"}`),
		[]byte(`{"fixture":"historical-v1"}`),
	)
	if err != nil {
		t.Fatalf("inserting fixture returned %v", err)
	}
	if err := database.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	restrictFixtureState(t, path)

	store, err = Open(ctx, path)
	if err != nil {
		t.Fatalf("second Open() returned %v", err)
	}
	defer store.Close()
	events, err := store.EventsAfter(ctx, 0, 10)
	if err != nil {
		t.Fatalf("EventsAfter() returned %v", err)
	}
	if len(events) != 1 || events[0].Cursor != 1 || events[0].Metadata["fixture"] != "historical-v1" {
		t.Fatalf("EventsAfter() = %#v", events)
	}
}

func restrictFixtureState(t *testing.T, paths ...string) {
	t.Helper()
	if len(paths) == 0 {
		t.Fatal("restrictFixtureState() requires one path")
	}
	if err := os.Chmod(filepath.Dir(paths[0]), 0o700); err != nil {
		t.Fatalf("Chmod() fixture directory returned %v", err)
	}
	for _, path := range paths {
		if err := os.Chmod(path, 0o600); err != nil {
			t.Fatalf("Chmod(%q) returned %v", path, err)
		}
	}
}

func TestFutureEventFixtureIsRejectedWithoutRewrite(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	database, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	payload := []byte(`{"future":true}`)
	_, err = database.Exec(
		`INSERT INTO events(
			schema_version, occurred_at, aggregate_kind, aggregate_id, event_type, payload, metadata
		) VALUES(?, ?, ?, ?, ?, ?, ?)`,
		2,
		time.Unix(10, 0).UTC().Format(time.RFC3339Nano),
		"session",
		"session-83",
		"future.event",
		payload,
		[]byte(`{}`),
	)
	if err != nil {
		t.Fatalf("inserting fixture returned %v", err)
	}
	if err := database.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	store, err = Open(ctx, path)
	if err != nil {
		t.Fatalf("second Open() returned %v", err)
	}
	if _, err := store.EventsAfter(ctx, 0, 10); !domain.IsErrorCode(err, domain.ErrorCodeUnsupportedVersion) {
		t.Fatalf("EventsAfter() error = %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	database, err = sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	defer database.Close()
	var version int
	var storedPayload []byte
	if err := database.QueryRow("SELECT schema_version, payload FROM events WHERE cursor = 1").Scan(
		&version,
		&storedPayload,
	); err != nil {
		t.Fatalf("reading fixture returned %v", err)
	}
	if version != 2 || !bytes.Equal(storedPayload, payload) {
		t.Fatalf("stored fixture has version %d and payload %q", version, storedPayload)
	}
}

func TestConcurrentEventAppendsPreserveCursorOrder(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()

	const eventCount = 32
	errors := make(chan error, eventCount)
	var wait sync.WaitGroup
	for index := 0; index < eventCount; index++ {
		index := index
		wait.Add(1)
		go func() {
			defer wait.Done()
			_, appendErr := store.AppendEvent(ctx, domain.EventEnvelope{
				SchemaVersion: domain.CurrentEventSchemaVersion,
				OccurredAt:    time.Unix(int64(index+1), 0).UTC(),
				Aggregate:     domain.ResourceReference{Kind: "node-run", ID: fmt.Sprintf("node-%d", index)},
				Type:          "node.completed",
				Payload:       json.RawMessage(`{}`),
			})
			errors <- appendErr
		}()
	}
	wait.Wait()
	close(errors)
	for err := range errors {
		if err != nil {
			t.Fatalf("AppendEvent() returned %v", err)
		}
	}

	events, err := store.EventsAfter(ctx, 0, eventCount)
	if err != nil {
		t.Fatalf("EventsAfter() returned %v", err)
	}
	if len(events) != eventCount {
		t.Fatalf("EventsAfter() count = %d", len(events))
	}
	for index, event := range events {
		if event.Cursor != domain.EventCursor(index+1) {
			t.Fatalf("event %d cursor = %d", index, event.Cursor)
		}
	}
}

func TestFullDatabaseRollsBackEventAppend(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	baseline := domain.EventEnvelope{
		SchemaVersion: domain.CurrentEventSchemaVersion,
		OccurredAt:    time.Unix(1, 0).UTC(),
		Aggregate:     domain.ResourceReference{Kind: "session", ID: "session-1"},
		Type:          "session.started",
		Payload:       json.RawMessage(`{}`),
	}
	if _, err := store.AppendEvent(ctx, baseline); err != nil {
		t.Fatalf("AppendEvent() returned %v", err)
	}
	var pageCount int64
	if err := store.db.QueryRowContext(ctx, "PRAGMA page_count").Scan(&pageCount); err != nil {
		t.Fatalf("reading page_count returned %v", err)
	}
	if _, err := store.db.ExecContext(ctx, fmt.Sprintf("PRAGMA max_page_count = %d", pageCount)); err != nil {
		t.Fatalf("setting max_page_count returned %v", err)
	}
	encodedPayload, err := json.Marshal(strings.Repeat("x", 1<<20))
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	fullEvent := baseline
	fullEvent.OccurredAt = time.Unix(2, 0).UTC()
	fullEvent.Payload = encodedPayload
	if _, err := store.AppendEvent(ctx, fullEvent); err == nil {
		t.Fatal("AppendEvent() succeeded on a full database")
	}
	events, err := store.EventsAfter(ctx, 0, 10)
	if err != nil {
		t.Fatalf("EventsAfter() returned %v", err)
	}
	if len(events) != 1 || events[0].Cursor != 1 {
		t.Fatalf("EventsAfter() = %#v", events)
	}
	if err := store.integrityCheck(ctx); err != nil {
		t.Fatalf("integrityCheck() returned %v", err)
	}
}

func TestEventBudgetsRejectLargeAndFastAppends(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	budgets := domain.DefaultBudgets()
	budgets.MaxEventBytes = 256
	budgets.MaxEventsPerSecond = 1
	store, err := OpenWithBudgets(ctx, filepath.Join(t.TempDir(), "colchis.db"), budgets)
	if err != nil {
		t.Fatalf("OpenWithBudgets() returned %v", err)
	}
	defer store.Close()
	large := storeTestEvent("large")
	large.Payload = json.RawMessage(`{"value":"` + strings.Repeat("x", 300) + `"}`)
	if _, err := store.AppendEvent(ctx, large); !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
		t.Fatalf("large AppendEvent() error = %v", err)
	}
	if _, err := store.AppendEvent(ctx, storeTestEvent("first")); err != nil {
		t.Fatalf("first AppendEvent() returned %v", err)
	}
	if _, err := store.AppendEvent(ctx, storeTestEvent("second")); !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
		t.Fatalf("second AppendEvent() error = %v", err)
	}
}

func TestEventReadBudgetBoundsResponse(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	budgets := domain.DefaultBudgets()
	budgets.MaxEventBytes = 180
	store, err := OpenWithBudgets(ctx, filepath.Join(t.TempDir(), "colchis.db"), budgets)
	if err != nil {
		t.Fatalf("OpenWithBudgets() returned %v", err)
	}
	defer store.Close()
	for _, id := range []string{"first", "second"} {
		event := storeTestEvent(id)
		event.Payload = json.RawMessage(`{"value":"` + strings.Repeat("x", 100) + `"}`)
		if _, err := store.AppendEvent(ctx, event); err != nil {
			t.Fatalf("AppendEvent() returned %v", err)
		}
	}
	if _, err := store.EventsAfter(ctx, 0, 2); !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
		t.Fatalf("EventsAfter() error = %v", err)
	}
	if _, err := store.EventsAfter(ctx, 0, 1001); !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("large EventsAfter() error = %v", err)
	}
}

func TestFullDatabaseRejectsCommandBeforeDispatch(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	var pageCount int
	if err := store.db.QueryRowContext(ctx, "PRAGMA page_count").Scan(&pageCount); err != nil {
		t.Fatalf("reading page count returned %v", err)
	}
	if _, err := store.db.ExecContext(ctx, fmt.Sprintf("PRAGMA max_page_count = %d", pageCount)); err != nil {
		t.Fatalf("setting max page count returned %v", err)
	}
	request := domain.CommandRequest{
		ID:             "command-full",
		IdempotencyKey: "request-full",
		Kind:           "workflow.patch",
		Payload:        json.RawMessage(`{"value":"` + strings.Repeat("x", 900<<10) + `"}`),
	}
	for attempt := 0; attempt < 2; attempt++ {
		if _, created, err := store.AcceptCommand(ctx, "owner:uid:501", request); err == nil || created {
			t.Fatalf("AcceptCommand() attempt %d = created %t, error %v", attempt+1, created, err)
		}
	}
	var records int
	if err := store.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM records").Scan(&records); err != nil {
		t.Fatalf("counting records returned %v", err)
	}
	if records != 0 {
		t.Fatalf("record count = %d", records)
	}
}

func TestCommandAdmissionAccountsForRecordAndJournalWrites(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	var pageCount uint64
	var pageSize uint64
	if err := store.db.QueryRowContext(ctx, "PRAGMA page_count").Scan(&pageCount); err != nil {
		t.Fatalf("reading page count returned %v", err)
	}
	if err := store.db.QueryRowContext(ctx, "PRAGMA page_size").Scan(&pageSize); err != nil {
		t.Fatalf("reading page size returned %v", err)
	}
	store.budgets.MaxStateBytes = pageCount*pageSize + store.budgets.EmergencyReserveBytes + 64<<10
	request := domain.CommandRequest{
		ID: "command-admission", IdempotencyKey: "request-admission", Kind: "workflow.patch",
		Payload: json.RawMessage(`{"value":"` + strings.Repeat("x", 128<<10) + `"}`),
	}
	if _, created, err := store.AcceptCommand(ctx, "owner:uid:501", request); !domain.IsErrorCode(
		err, domain.ErrorCodeBudgetExhausted,
	) || created {
		t.Fatalf("AcceptCommand() = created %t, error %v", created, err)
	}
	var records int
	if err := store.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM records").Scan(&records); err != nil {
		t.Fatalf("counting records returned %v", err)
	}
	if records != 0 {
		t.Fatalf("record count = %d", records)
	}
}

func TestEmergencyReservePersistsTerminalStateAndRecordsDegradedStore(t *testing.T) {
	ctx := context.Background()
	budgets := domain.DefaultBudgets()
	budgets.MaxStateBytes = 16 << 20
	budgets.EmergencyReserveBytes = 1 << 20
	budgets.MaxEventBytes = 64 << 10
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := OpenWithBudgets(ctx, path, budgets)
	if err != nil {
		t.Fatalf("OpenWithBudgets() returned %v", err)
	}
	defer store.Close()
	if err := store.EnableEmergencyReserve(); err != nil {
		t.Fatalf("EnableEmergencyReserve() returned %v", err)
	}
	reservePath := filepath.Join(filepath.Dir(path), emergencyReserveName)
	info, err := os.Stat(reservePath)
	if err != nil {
		t.Fatalf("Stat() returned %v", err)
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok {
		t.Fatal("reserve stat lacks filesystem blocks")
	}
	if uint64(stat.Blocks)*512 < budgets.EmergencyReserveBytes {
		t.Fatalf("reserve blocks = %d", stat.Blocks)
	}
	request := domain.CommandRequest{
		ID: "command-reserve", IdempotencyKey: "request-reserve", Kind: "workflow.patch",
		Payload: json.RawMessage(`{}`),
	}
	if _, created, err := store.AcceptCommand(ctx, "owner:uid:501", request); err != nil || !created {
		t.Fatalf("AcceptCommand() = created %t, error %v", created, err)
	}
	if _, claimed, err := store.ClaimCommand(ctx, request.ID); err != nil || !claimed {
		t.Fatalf("ClaimCommand() = claimed %t, error %v", claimed, err)
	}
	originalAllocator := allocateEmergencyReserveFile
	allocateEmergencyReserveFile = func(*os.File, int64) error { return unix.ENOSPC }
	t.Cleanup(func() { allocateEmergencyReserveFile = originalAllocator })
	record, err := store.FinishCommand(ctx, request.ID, domain.CommandStateSucceeded)
	if err != nil {
		t.Fatalf("FinishCommand() returned %v", err)
	}
	if record.State != domain.CommandStateSucceeded {
		t.Fatalf("FinishCommand() state = %q", record.State)
	}
	inspection, err := store.Inspect(ctx)
	if err != nil {
		t.Fatalf("Inspect() returned %v", err)
	}
	if !inspection.Degraded {
		t.Fatal("Inspect() did not report degraded state")
	}
	unregisterWriter(path)
	restartBudgets := budgets
	restartBudgets.MaxStateBytes = 1
	version, exists, versionErr := existingSchemaVersion(ctx, path, restartBudgets)
	registerWriter(path)
	if versionErr != nil || !exists || version != currentSchemaVersion {
		t.Fatalf("existingSchemaVersion() = version %d, exists %t, error %v", version, exists, versionErr)
	}
	if err := store.EnableEmergencyReserve(); err != nil {
		t.Fatalf("degraded EnableEmergencyReserve() returned %v", err)
	}
	if _, _, err := store.AcceptCommand(ctx, "owner:uid:501", domain.CommandRequest{
		ID: "command-blocked", IdempotencyKey: "request-blocked", Kind: "workflow.patch",
		Payload: json.RawMessage(`{}`),
	}); !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
		t.Fatalf("AcceptCommand() error = %v", err)
	}
}

func TestEmergencyReserveRemovesCrashedStagingFiles(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	stale := make([]string, 2)
	for index := range stale {
		file, err := os.CreateTemp(filepath.Dir(path), emergencyReserveName+"-")
		if err != nil {
			t.Fatalf("CreateTemp() returned %v", err)
		}
		stale[index] = file.Name()
		if err := errors.Join(file.Truncate(4096), file.Close()); err != nil {
			t.Fatalf("creating stale reserve returned %v", err)
		}
		if index == 0 {
			if err := os.Chmod(stale[index], 0); err != nil {
				t.Fatalf("Chmod() stale reserve returned %v", err)
			}
		}
	}
	if err := store.EnableEmergencyReserve(); err != nil {
		t.Fatalf("EnableEmergencyReserve() returned %v", err)
	}
	for _, stalePath := range stale {
		if _, err := os.Stat(stalePath); !errors.Is(err, os.ErrNotExist) {
			t.Fatalf("stale reserve remains: %v", err)
		}
	}
}

func TestEmergencyReservePreservesActiveStagingFile(t *testing.T) {
	t.Parallel()

	stateDirectory := t.TempDir()
	active, err := os.CreateTemp(stateDirectory, emergencyReserveName+"-")
	if err != nil {
		t.Fatalf("CreateTemp() returned %v", err)
	}
	activePath := active.Name()
	if err := unix.Flock(int(active.Fd()), unix.LOCK_EX|unix.LOCK_NB); err != nil {
		t.Fatalf("Flock() returned %v", err)
	}
	if err := cleanupEmergencyReserveStaging(stateDirectory); err != nil {
		t.Fatalf("cleanupEmergencyReserveStaging() returned %v", err)
	}
	if _, err := os.Stat(activePath); err != nil {
		t.Fatalf("active staging changed: %v", err)
	}
	if err := unix.Flock(int(active.Fd()), unix.LOCK_UN); err != nil {
		t.Fatalf("unlock staging returned %v", err)
	}
	if err := active.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	if err := cleanupEmergencyReserveStaging(stateDirectory); err != nil {
		t.Fatalf("second cleanupEmergencyReserveStaging() returned %v", err)
	}
	if _, err := os.Stat(activePath); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("released staging remains: %v", err)
	}
}

func TestEmergencyReserveSerializesStateTransitions(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "colchis.db")
	reserveBytes := uint64(1 << 20)
	if err := ensureEmergencyReserve(path, reserveBytes); err != nil {
		t.Fatalf("ensureEmergencyReserve() returned %v", err)
	}
	lock, err := acquireEmergencyStateLock(path)
	if err != nil {
		t.Fatalf("acquireEmergencyStateLock() returned %v", err)
	}
	released := make(chan error, 1)
	go func() {
		released <- releaseEmergencyReserve(path, reserveBytes)
	}()
	select {
	case err := <-released:
		lock.Close()
		t.Fatalf("releaseEmergencyReserve() bypassed the state lock: %v", err)
	case <-time.After(100 * time.Millisecond):
	}
	if err := lock.Close(); err != nil {
		t.Fatalf("Close() state lock returned %v", err)
	}
	if err := <-released; err != nil {
		t.Fatalf("releaseEmergencyReserve() returned %v", err)
	}
	if err := ensureEmergencyReserve(path, reserveBytes); err != nil {
		t.Fatalf("second ensureEmergencyReserve() returned %v", err)
	}
	if healthy, err := emergencyFileHasSize(
		filepath.Join(filepath.Dir(path), emergencyReserveName), reserveBytes,
	); err != nil || !healthy {
		t.Fatalf("emergencyFileHasSize() = healthy %t, error %v", healthy, err)
	}
}

func TestOversizedDegradedMarkerRecoversAfterInterruptedRelease(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "colchis.db")
	marker := []byte(`{"schemaVersion":3}`)
	contents := make([]byte, 1<<20)
	copy(contents, marker)
	degradedPath := filepath.Join(filepath.Dir(path), emergencyDegradedName)
	if err := os.WriteFile(degradedPath, contents, 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	version, degraded, err := degradedSchemaVersion(path)
	if err != nil || !degraded || version != currentSchemaVersion {
		t.Fatalf("degradedSchemaVersion() = version %d, degraded %t, error %v", version, degraded, err)
	}
}

func TestMigrationAdvancesDegradedSchemaBeforeDatabaseChanges(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "colchis.db")
	degradedPath := filepath.Join(filepath.Dir(path), emergencyDegradedName)
	if err := os.WriteFile(degradedPath, []byte(`{"schemaVersion":1}`), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	if err := advanceDegradedSchemaVersion(path, 2); err != nil {
		t.Fatalf("advanceDegradedSchemaVersion() returned %v", err)
	}
	version, degraded, err := degradedSchemaVersion(path)
	if err != nil || !degraded || version != 2 {
		t.Fatalf("degradedSchemaVersion() = version %d, degraded %t, error %v", version, degraded, err)
	}
}

func TestStateBudgetIncludesBlockedWriteAheadLog(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	reader, err := sql.Open("sqlite", "file:"+path+"?mode=ro")
	if err != nil {
		t.Fatalf("sql.Open() reader returned %v", err)
	}
	defer reader.Close()
	transaction, err := reader.BeginTx(ctx, &sql.TxOptions{ReadOnly: true})
	if err != nil {
		t.Fatalf("BeginTx() returned %v", err)
	}
	defer transaction.Rollback()
	var events int
	if err := transaction.QueryRowContext(ctx, "SELECT COUNT(*) FROM events").Scan(&events); err != nil {
		t.Fatalf("reading events returned %v", err)
	}
	physicalBytes, err := physicalStateBytes(path)
	if err != nil {
		t.Fatalf("physicalStateBytes() returned %v", err)
	}
	store.budgets.MaxStateBytes = physicalBytes + store.budgets.EmergencyReserveBytes + 256<<10
	exhausted := false
	for index := 0; index < 10; index++ {
		event := storeTestEvent(fmt.Sprintf("wal-%d", index))
		event.Payload = json.RawMessage(`{"value":"` + strings.Repeat("x", 64<<10) + `"}`)
		if _, err := store.AppendEvent(ctx, event); domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
			exhausted = true
			break
		} else if err != nil {
			t.Fatalf("AppendEvent() returned %v", err)
		}
	}
	if !exhausted {
		t.Fatal("AppendEvent() did not enforce the physical state budget")
	}
	physicalBytes, err = physicalStateBytes(path)
	if err != nil {
		t.Fatalf("physicalStateBytes() after appends returned %v", err)
	}
	if physicalBytes > store.budgets.MaxStateBytes-store.budgets.EmergencyReserveBytes {
		t.Fatalf("physical state bytes = %d", physicalBytes)
	}
}

func TestOpenReadOnlyInspectsWithoutChangingDatabase(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	event := domain.EventEnvelope{
		SchemaVersion: domain.CurrentEventSchemaVersion,
		OccurredAt:    time.Unix(10, 0).UTC(),
		Aggregate:     domain.ResourceReference{Kind: "session", ID: "session-83"},
		Type:          "owner.message",
		Payload:       json.RawMessage(`{"text":"continue"}`),
	}
	if _, err := store.AppendEvent(ctx, event); err != nil {
		t.Fatalf("AppendEvent() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	before, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}

	store, err = OpenReadOnly(ctx, path)
	if err != nil {
		t.Fatalf("OpenReadOnly() returned %v", err)
	}
	inspection, err := store.Inspect(ctx)
	if err != nil {
		t.Fatalf("Inspect() returned %v", err)
	}
	if inspection.SchemaVersion != currentSchemaVersion || inspection.Integrity != "ok" {
		t.Fatalf("Inspect() metadata = %#v", inspection)
	}
	if inspection.LastEventCursor != 1 {
		t.Fatalf("Inspect() last cursor = %d", inspection.LastEventCursor)
	}
	eventRows, found := rowsForTable(inspection.Tables, "events")
	if !found || eventRows != 1 {
		t.Fatalf("Inspect() tables = %#v", inspection.Tables)
	}
	if _, err := store.AppendEvent(ctx, event); !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("AppendEvent() error = %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	after, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	if !bytes.Equal(before, after) {
		t.Fatal("read-only inspection changed the database")
	}
}

func TestOpenWithBudgetsReopensStateLargerThanSnapshotBudget(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	budgets := domain.DefaultBudgets()
	budgets.MaxSnapshotBytes = 1 << 20
	store, err := OpenWithBudgets(ctx, path, budgets)
	if err != nil {
		t.Fatalf("OpenWithBudgets() returned %v", err)
	}
	for index := 0; index < 3; index++ {
		event := storeTestEvent(fmt.Sprintf("restart-large-%d", index))
		event.Payload = json.RawMessage(`{"value":"` + strings.Repeat("x", 700<<10) + `"}`)
		if _, err := store.AppendEvent(ctx, event); err != nil {
			t.Fatalf("AppendEvent() returned %v", err)
		}
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	info, err := os.Stat(path)
	if err != nil {
		t.Fatalf("Stat() returned %v", err)
	}
	if info.Size() <= int64(budgets.MaxSnapshotBytes) {
		t.Fatalf("database size = %d", info.Size())
	}
	store, err = OpenWithBudgets(ctx, path, budgets)
	if err != nil {
		t.Fatalf("reopening store returned %v", err)
	}
	defer store.Close()
}

func TestExportToPreservesLargeValuesWithoutStateScratchSpace(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	if _, err := store.db.ExecContext(ctx, "CREATE TABLE export_large (payload BLOB NOT NULL)"); err != nil {
		t.Fatalf("creating export table returned %v", err)
	}
	if _, err := store.db.ExecContext(ctx, "INSERT INTO export_large (payload) VALUES (?)", bytes.Repeat([]byte{0xa5}, 2<<20)); err != nil {
		t.Fatalf("inserting export value returned %v", err)
	}

	exportPath := filepath.Join(t.TempDir(), "export.sqlite3")
	if err := store.ExportTo(ctx, exportPath); err != nil {
		t.Fatalf("ExportTo() returned %v", err)
	}
	exported, err := sql.Open("sqlite", exportPath)
	if err != nil {
		t.Fatalf("opening export returned %v", err)
	}
	defer exported.Close()
	var length int
	if err := exported.QueryRowContext(ctx, "SELECT length(payload) FROM export_large").Scan(&length); err != nil {
		t.Fatalf("reading export returned %v", err)
	}
	if length != 2<<20 {
		t.Fatalf("exported payload length = %d", length)
	}
}

func TestExportToWorksFromReadOnlySourceDirectory(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	sourceDirectory := t.TempDir()
	path := filepath.Join(sourceDirectory, "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	if err := os.Chmod(sourceDirectory, 0o500); err != nil {
		t.Fatalf("Chmod() returned %v", err)
	}
	defer os.Chmod(sourceDirectory, 0o700)
	store, err = OpenReadOnly(ctx, path)
	if err != nil {
		t.Fatalf("OpenReadOnly() returned %v", err)
	}
	defer store.Close()
	if store.immutableLock == nil && store.readOnlyCleanup == "" {
		t.Fatal("OpenReadOnly() did not isolate source state")
	}
	exportPath := filepath.Join(t.TempDir(), "export.sqlite3")
	if err := store.ExportTo(ctx, exportPath); err != nil {
		t.Fatalf("ExportTo() returned %v", err)
	}
}

func TestExportToSnapshotsPermissionReadOnlySource(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	sourceDirectory := t.TempDir()
	path := filepath.Join(sourceDirectory, "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	if err := os.Chmod(path, 0o400); err != nil {
		t.Fatalf("Chmod() database returned %v", err)
	}
	if err := os.Chmod(sourceDirectory, 0o500); err != nil {
		t.Fatalf("Chmod() directory returned %v", err)
	}
	defer os.Chmod(sourceDirectory, 0o700)
	defer os.Chmod(path, 0o600)
	scratchParent := t.TempDir()
	store, err = OpenReadOnlyIn(ctx, path, scratchParent)
	if err != nil {
		t.Fatalf("OpenReadOnly() returned %v", err)
	}
	if store.readOnlyCleanup == "" {
		t.Fatal("OpenReadOnly() did not snapshot the permission read-only source")
	}
	cleanupPath := store.readOnlyCleanup
	relativeCleanup, err := filepath.Rel(scratchParent, cleanupPath)
	if err != nil || relativeCleanup == ".." || strings.HasPrefix(relativeCleanup, ".."+string(os.PathSeparator)) {
		t.Fatalf("snapshot path = %q, relative path = %q, error = %v", cleanupPath, relativeCleanup, err)
	}
	exportPath := filepath.Join(t.TempDir(), "export.sqlite3")
	if err := store.ExportTo(ctx, exportPath); err != nil {
		t.Fatalf("ExportTo() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	if _, err := os.Stat(cleanupPath); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("snapshot remains after Close(): %v", err)
	}
}

func TestCreateSnapshotDirectoryRemovesCrashRemainder(t *testing.T) {
	t.Parallel()

	parent := t.TempDir()
	base := filepath.Join(parent, fmt.Sprintf(".colchis-readonly-%d", os.Geteuid()))
	stale := filepath.Join(base, "snapshot-stale")
	if err := os.MkdirAll(stale, 0o700); err != nil {
		t.Fatalf("MkdirAll() returned %v", err)
	}
	if err := os.WriteFile(filepath.Join(base, "lease-stale"), nil, 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	if err := os.WriteFile(filepath.Join(stale, "state.sqlite3"), []byte("private"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	directory, lease, err := createSnapshotDirectory(parent, domain.DefaultBudgets().MaxMaterializedSnapshots)
	if err != nil {
		t.Fatalf("createSnapshotDirectory() returned %v", err)
	}
	defer lease.Close()
	defer os.RemoveAll(directory)
	if _, err := os.Stat(stale); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("stale snapshot remains: %v", err)
	}
}

func TestCreateSnapshotDirectoryIsConcurrent(t *testing.T) {
	t.Parallel()

	parent := t.TempDir()
	count := int(domain.DefaultBudgets().MaxMaterializedSnapshots)
	type result struct {
		directory string
		lease     *os.File
		err       error
	}
	results := make(chan result, count)
	for index := 0; index < count; index++ {
		go func() {
			directory, lease, err := createSnapshotDirectory(
				parent, domain.DefaultBudgets().MaxMaterializedSnapshots,
			)
			results <- result{directory: directory, lease: lease, err: err}
		}()
	}
	for index := 0; index < count; index++ {
		created := <-results
		if created.err != nil {
			t.Fatalf("createSnapshotDirectory() returned %v", created.err)
		}
		if _, err := os.Stat(created.directory); err != nil {
			t.Fatalf("snapshot directory is unavailable: %v", err)
		}
		defer cleanupReadOnlySnapshot(created.directory, created.lease)
	}
	_, _, err := createSnapshotDirectory(parent, domain.DefaultBudgets().MaxMaterializedSnapshots)
	if !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
		t.Fatalf("extra createSnapshotDirectory() error = %v", err)
	}
}

func TestSnapshotBudgetsControlBytesAndMaterializations(t *testing.T) {
	t.Parallel()

	parent := t.TempDir()
	budgets := domain.DefaultBudgets()
	budgets.MaxMaterializedSnapshots = 1
	directory, lease, err := createSnapshotDirectory(parent, budgets.MaxMaterializedSnapshots)
	if err != nil {
		t.Fatalf("createSnapshotDirectory() returned %v", err)
	}
	defer cleanupReadOnlySnapshot(directory, lease)
	if _, _, err := createSnapshotDirectory(parent, budgets.MaxMaterializedSnapshots); !domain.IsErrorCode(
		err, domain.ErrorCodeBudgetExhausted,
	) {
		t.Fatalf("second createSnapshotDirectory() error = %v", err)
	}

	path := filepath.Join(t.TempDir(), "source.db")
	if err := os.WriteFile(path, bytes.Repeat([]byte{0xa5}, 1024), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	budgets.MaxSnapshotBytes = 512
	_, _, _, _, err = snapshotReadOnlyDataSource(path, t.TempDir(), budgets)
	if !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
		t.Fatalf("snapshotReadOnlyDataSource() error = %v", err)
	}
}

func TestReadOnlySnapshotsShareMaterializationLimitAcrossScratchRoots(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	first, err := OpenReadOnlyIn(ctx, path, t.TempDir())
	if err != nil {
		t.Fatalf("first OpenReadOnlyIn() returned %v", err)
	}
	defer first.Close()
	if _, err := OpenReadOnlyIn(ctx, path, t.TempDir()); !domain.IsErrorCode(
		err, domain.ErrorCodeBudgetExhausted,
	) {
		t.Fatalf("second OpenReadOnlyIn() error = %v", err)
	}
}

func TestSnapshotPreflightPreservesFilesystemReserve(t *testing.T) {
	t.Parallel()

	parent := t.TempDir()
	path := filepath.Join(parent, "source.db")
	if err := os.WriteFile(path, bytes.Repeat([]byte{0xa5}, 4096), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	budgets := domain.DefaultBudgets()
	budgets.EmergencyReserveBytes = ^uint64(0)
	if _, err := preflightSnapshotSource(path, parent, budgets); !domain.IsErrorCode(
		err, domain.ErrorCodeBudgetExhausted,
	) {
		t.Fatalf("preflightSnapshotSource() error = %v", err)
	}
}

func TestOpenReadOnlyCleansCrashRemainderWithoutSnapshot(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	parent := t.TempDir()
	base := filepath.Join(parent, fmt.Sprintf(".colchis-readonly-%d", os.Geteuid()))
	stale := filepath.Join(base, "snapshot-stale")
	if err := os.MkdirAll(stale, 0o700); err != nil {
		t.Fatalf("MkdirAll() returned %v", err)
	}
	if err := os.WriteFile(filepath.Join(base, "lease-stale"), nil, 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	store, err = OpenReadOnlyIn(ctx, path, parent)
	if err != nil {
		t.Fatalf("OpenReadOnlyIn() returned %v", err)
	}
	defer store.Close()
	if _, err := os.Stat(stale); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("stale snapshot remains: %v", err)
	}
}

func TestOpenReadOnlyIgnoresUntrustedLegacyScratchDirectory(t *testing.T) {
	ctx := context.Background()
	scratchParent := t.TempDir()
	legacy := filepath.Join(scratchParent, fmt.Sprintf(".colchis-readonly-%d", os.Geteuid()))
	if err := os.Mkdir(legacy, 0o755); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	reader, err := OpenReadOnlyIn(ctx, path, scratchParent)
	if err != nil {
		t.Fatalf("OpenReadOnlyIn() returned %v", err)
	}
	if err := reader.Close(); err != nil {
		t.Fatalf("Close() reader returned %v", err)
	}
	if _, err := os.Stat(legacy); err != nil {
		t.Fatalf("legacy collision changed: %v", err)
	}
}

func TestExportIgnoresUntrustedLegacyScratchDirectory(t *testing.T) {
	ctx := context.Background()
	targetParent := t.TempDir()
	legacy := filepath.Join(targetParent, fmt.Sprintf(".colchis-readonly-%d", os.Geteuid()))
	if err := os.Mkdir(legacy, 0o755); err != nil {
		t.Fatalf("Mkdir() returned %v", err)
	}
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	target := filepath.Join(targetParent, "export.db")
	if err := store.ExportTo(ctx, target); err != nil {
		t.Fatalf("ExportTo() returned %v", err)
	}
	if _, err := os.Stat(target); err != nil {
		t.Fatalf("export is unavailable: %v", err)
	}
	if _, err := os.Stat(legacy); err != nil {
		t.Fatalf("legacy collision changed: %v", err)
	}
}

func TestOpenReadOnlyCleansDefaultCrashRemainder(t *testing.T) {
	ctx := context.Background()
	parent := t.TempDir()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	stale, staleLease, err := createTemporarySnapshotRoot(parent, path, 1)
	if err != nil {
		t.Fatalf("createTemporarySnapshotRoot() returned %v", err)
	}
	snapshotProcessState.Lock()
	delete(snapshotProcessState.activeLeases, staleLease.Name())
	snapshotProcessState.Unlock()
	if err := staleLease.Close(); err != nil {
		t.Fatalf("stale lease Close() returned %v", err)
	}
	root, lease, err := createTemporarySnapshotRoot(parent, path, 1)
	if err != nil {
		t.Fatalf("second createTemporarySnapshotRoot() returned %v", err)
	}
	defer cleanupTemporarySnapshotRoot(root, lease)
	if _, err := os.Stat(stale); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("stale snapshot remains: %v", err)
	}
}

func TestCreateTemporarySnapshotRootIgnoresParentDirectoryLock(t *testing.T) {
	ctx := context.Background()
	parent := t.TempDir()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	directory, err := os.Open(parent)
	if err != nil {
		t.Fatalf("Open() parent returned %v", err)
	}
	defer directory.Close()
	if err := unix.Flock(int(directory.Fd()), unix.LOCK_EX|unix.LOCK_NB); err != nil {
		t.Fatalf("Flock() parent returned %v", err)
	}
	root, lease, err := createTemporarySnapshotRoot(parent, path, 1)
	if err != nil {
		t.Fatalf("createTemporarySnapshotRoot() returned %v", err)
	}
	defer cleanupTemporarySnapshotRoot(root, lease)
}

func TestCreateTemporarySnapshotRootIgnoresAnotherSourceRoot(t *testing.T) {
	ctx := context.Background()
	parent := t.TempDir()
	firstPath := filepath.Join(t.TempDir(), "first.db")
	secondPath := filepath.Join(t.TempDir(), "second.db")
	for _, path := range []string{firstPath, secondPath} {
		store, err := Open(ctx, path)
		if err != nil {
			t.Fatalf("Open(%q) returned %v", path, err)
		}
		if err := store.Close(); err != nil {
			t.Fatalf("Close(%q) returned %v", path, err)
		}
	}
	incomplete, err := os.MkdirTemp(parent, temporarySnapshotPrefix(firstPath))
	if err != nil {
		t.Fatalf("MkdirTemp() returned %v", err)
	}
	defer os.RemoveAll(incomplete)
	root, lease, err := createTemporarySnapshotRoot(parent, secondPath, 1)
	if err != nil {
		t.Fatalf("createTemporarySnapshotRoot() returned %v", err)
	}
	defer cleanupTemporarySnapshotRoot(root, lease)
	if _, err := os.Stat(incomplete); err != nil {
		t.Fatalf("another source root changed: %v", err)
	}
}

func TestOpenReadOnlyRemovesTemporaryRootOnClose(t *testing.T) {
	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	reader, err := OpenReadOnly(ctx, path)
	if err != nil {
		t.Fatalf("OpenReadOnly() returned %v", err)
	}
	root := reader.readOnlyScratch
	if err := reader.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	if _, err := os.Stat(root); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("temporary root remains: %v", err)
	}
}

func TestOpenReadOnlyObservesWriterCommitsWithoutImmutableMode(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	writer, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer writer.Close()
	reader, err := OpenReadOnly(ctx, path)
	if err != nil {
		t.Fatalf("OpenReadOnly() returned %v", err)
	}
	defer reader.Close()
	if reader.immutableLock != nil || reader.readOnlyCleanup != "" {
		t.Fatal("OpenReadOnly() isolated an active local writer")
	}
	if _, err := writer.AppendEvent(ctx, storeTestEvent("live-writer")); err != nil {
		t.Fatalf("AppendEvent() returned %v", err)
	}
	events, err := reader.EventsAfter(ctx, 0, 10)
	if err != nil {
		t.Fatalf("EventsAfter() returned %v", err)
	}
	if len(events) != 1 || events[0].Aggregate.ID != "session-live-writer" {
		t.Fatalf("EventsAfter() events = %#v", events)
	}
}

func TestExportToRefusesExistingTarget(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	exportPath := filepath.Join(t.TempDir(), "export.sqlite3")
	if err := os.WriteFile(exportPath, []byte("owner-data"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	if err := store.ExportTo(ctx, exportPath); !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("existing target ExportTo() error = %v", err)
	}
	contents, err := os.ReadFile(exportPath)
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	if string(contents) != "owner-data" {
		t.Fatalf("export target = %q", contents)
	}
}

func TestExportToIgnoresUnrelatedTargetDirectoryLock(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	targetDirectory := t.TempDir()
	descriptor, err := unix.Open(targetDirectory, unix.O_RDONLY|unix.O_CLOEXEC|unix.O_DIRECTORY, 0)
	if err != nil {
		t.Fatalf("opening target directory returned %v", err)
	}
	lockedDirectory := os.NewFile(uintptr(descriptor), targetDirectory)
	defer lockedDirectory.Close()
	if err := unix.Flock(descriptor, unix.LOCK_EX|unix.LOCK_NB); err != nil {
		t.Fatalf("locking target directory returned %v", err)
	}
	exportPath := filepath.Join(targetDirectory, "export.sqlite3")
	if err := store.ExportTo(ctx, exportPath); err != nil {
		t.Fatalf("ExportTo() returned %v", err)
	}
}

func TestOpenReadOnlyInspectsNewerSchema(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "colchis.db")
	database, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open() returned %v", err)
	}
	if _, err := database.Exec("CREATE TABLE future_state(id INTEGER); PRAGMA user_version = 4"); err != nil {
		t.Fatalf("creating future schema returned %v", err)
	}
	if err := database.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}
	restrictFixtureState(t, path)

	store, err := OpenReadOnly(context.Background(), path)
	if err != nil {
		t.Fatalf("OpenReadOnly() returned %v", err)
	}
	defer store.Close()
	inspection, err := store.Inspect(context.Background())
	if err != nil {
		t.Fatalf("Inspect() returned %v", err)
	}
	futureRows, found := rowsForTable(inspection.Tables, "future_state")
	if inspection.SchemaVersion != 4 || !found || futureRows != 0 {
		t.Fatalf("Inspect() = %#v", inspection)
	}
}

func rowsForTable(tables []TableInspection, name string) (uint64, bool) {
	for _, table := range tables {
		if table.Name == name {
			return table.Rows, true
		}
	}
	return 0, false
}

func storeTestEvent(identifier string) domain.EventEnvelope {
	return domain.EventEnvelope{
		SchemaVersion: domain.CurrentEventSchemaVersion,
		OccurredAt:    time.Unix(10, 0).UTC(),
		Aggregate:     domain.ResourceReference{Kind: "session", ID: "session-" + identifier},
		Type:          "session.test",
		Payload:       json.RawMessage(`{}`),
	}
}

func TestTransactionRollsBackEvent(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()

	event := domain.EventEnvelope{
		SchemaVersion: domain.CurrentEventSchemaVersion,
		OccurredAt:    time.Unix(10, 0).UTC(),
		Aggregate:     domain.ResourceReference{Kind: "session", ID: "session-83"},
		Type:          "owner.message",
		Payload:       json.RawMessage(`{"text":"continue"}`),
	}
	expected := &domain.Error{Code: domain.ErrorCodeConflict, Message: "stop"}
	err = store.Transaction(ctx, func(transaction *Tx) error {
		if _, appendErr := transaction.AppendEvent(ctx, event); appendErr != nil {
			return appendErr
		}
		return expected
	})
	if err != expected {
		t.Fatalf("Transaction() error = %v", err)
	}

	events, err := store.EventsAfter(ctx, 0, 10)
	if err != nil {
		t.Fatalf("EventsAfter() returned %v", err)
	}
	if len(events) != 0 {
		t.Fatalf("EventsAfter() count = %d", len(events))
	}
}
