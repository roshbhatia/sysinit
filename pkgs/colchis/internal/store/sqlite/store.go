package sqlite

import (
	"bytes"
	"context"
	"crypto/sha256"
	"database/sql"
	_ "embed"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"golang.org/x/sys/unix"
	_ "modernc.org/sqlite"
)

const currentSchemaVersion = 3

const (
	emergencyReserveName    = ".emergency-reserve"
	emergencyDegradedName   = ".emergency-degraded"
	emergencyLockName       = ".emergency-lock"
	materializationLockName = ".materialization-lock"
)

//go:embed migrations/001_initial.sql
var initialSchema string

var errReadOnlySnapshotRequired = errors.New("read-only source requires a local snapshot")

var allocateEmergencyReserveFile = allocateEmergencyFile

type Store struct {
	db               *sql.DB
	path             string
	budgets          domain.Budgets
	eventRate        *eventRateLimiter
	readOnly         bool
	immutableLock    *os.File
	readOnlyCleanup  string
	readOnlyLease    *os.File
	readOnlyScratch  string
	scratchLease     *os.File
	writerRegistered bool
	emergencyReserve bool
	exportMu         sync.Mutex
}

var writerRegistry = struct {
	sync.Mutex
	paths            map[string]uint32
	materializations map[string]struct{}
}{
	paths:            make(map[string]uint32),
	materializations: make(map[string]struct{}),
}

var snapshotProcessState = struct {
	sync.Mutex
	activeLeases map[string]struct{}
}{activeLeases: make(map[string]struct{})}

type Tx struct {
	tx               *sql.Tx
	path             string
	budgets          domain.Budgets
	eventRate        *eventRateLimiter
	emergencyReserve bool
	reserveReleased  bool
}

type eventRateLimiter struct {
	sync.Mutex
	window time.Time
	count  uint32
}

func Open(ctx context.Context, path string) (*Store, error) {
	return OpenWithBudgets(ctx, path, domain.DefaultBudgets())
}

func OpenWithBudgets(ctx context.Context, path string, budgets domain.Budgets) (*Store, error) {
	if err := budgets.Validate(); err != nil {
		return nil, err
	}
	stateDirectory := filepath.Dir(path)
	if err := PrepareStateDirectory(stateDirectory); err != nil {
		return nil, err
	}
	if err := secureDatabaseFile(path); err != nil {
		return nil, err
	}
	if err := ensureMaterializationLock(path); err != nil {
		return nil, err
	}
	version, exists, err := existingSchemaVersion(ctx, path, budgets)
	if err != nil {
		return nil, err
	}
	if exists && version > currentSchemaVersion {
		return nil, unsupportedSchemaVersion(path, version)
	}

	store, err := openDatabase(ctx, path)
	if err != nil {
		return nil, err
	}
	store.budgets = budgets
	if err := store.prepare(ctx, exists); err != nil {
		store.db.Close()
		return nil, err
	}
	if err := os.Chmod(store.path, 0o600); err != nil {
		store.db.Close()
		return nil, wrap("restrict database", store.path, err)
	}
	registerWriter(store.path)
	store.writerRegistered = true
	return store, nil
}

func (store *Store) EnableEmergencyReserve() error {
	if store.readOnly {
		return &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "enable emergency reserve", Resource: store.path,
			Message: "database is read-only",
		}
	}
	if store.budgets.EmergencyReserveBytes > uint64(^uint64(0)>>1) {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "enable emergency reserve", Resource: store.path,
			Message: "emergency reserve exceeds the supported file size",
		}
	}
	if err := ensureEmergencyReserve(store.path, store.budgets.EmergencyReserveBytes); err != nil {
		version, degraded, markerErr := degradedSchemaVersion(store.path)
		if markerErr != nil || !degraded || version > currentSchemaVersion ||
			(!errors.Is(err, unix.ENOSPC) && !errors.Is(err, unix.EDQUOT)) {
			return errors.Join(err, markerErr)
		}
	}
	store.emergencyReserve = true
	return nil
}

func ensureEmergencyReserve(databasePath string, reserveBytes uint64) error {
	lock, err := acquireEmergencyStateLock(databasePath)
	if err != nil {
		return err
	}
	defer lock.Close()
	stateDirectory := filepath.Dir(databasePath)
	reservePath := filepath.Join(stateDirectory, emergencyReserveName)
	degradedPath := filepath.Join(stateDirectory, emergencyDegradedName)
	if err := cleanupEmergencyReserveStaging(stateDirectory); err != nil {
		return err
	}
	if healthy, err := emergencyFileHasSize(reservePath, reserveBytes); err != nil {
		return err
	} else if healthy {
		if err := os.Remove(degradedPath); err != nil && !errors.Is(err, os.ErrNotExist) {
			return wrap("clear degraded state", degradedPath, err)
		}
		return nil
	}
	if reusable, err := emergencyFileHasSize(degradedPath, reserveBytes); err != nil {
		return err
	} else if reusable {
		if err := os.Rename(degradedPath, reservePath); err != nil {
			return wrap("restore emergency reserve", reservePath, err)
		}
		return syncStateDirectory(stateDirectory)
	}
	reserve, err := os.CreateTemp(stateDirectory, ".emergency-reserve-")
	if err != nil {
		return wrap("create emergency reserve", stateDirectory, err)
	}
	temporaryPath := reserve.Name()
	reserveClosed := false
	defer func() {
		if !reserveClosed {
			reserve.Close()
		}
		os.Remove(temporaryPath)
	}()
	if err := reserve.Chmod(0o600); err != nil {
		return wrap("restrict emergency reserve staging", temporaryPath, err)
	}
	if err := unix.Flock(int(reserve.Fd()), unix.LOCK_EX|unix.LOCK_NB); err != nil {
		return wrap("lease emergency reserve staging", temporaryPath, err)
	}
	if err := allocateEmergencyReserveFile(reserve, int64(reserveBytes)); err != nil {
		return wrap("allocate emergency reserve", temporaryPath, err)
	}
	if err := reserve.Sync(); err != nil {
		return wrap("sync emergency reserve", temporaryPath, err)
	}
	if err := os.Rename(temporaryPath, reservePath); err != nil {
		return wrap("publish emergency reserve", reservePath, err)
	}
	if err := os.Remove(degradedPath); err != nil && !errors.Is(err, os.ErrNotExist) {
		return wrap("clear degraded state", degradedPath, err)
	}
	syncErr := syncStateDirectory(stateDirectory)
	closeErr := reserve.Close()
	reserveClosed = true
	if err := errors.Join(syncErr, closeErr); err != nil {
		return wrap("publish emergency reserve", reservePath, err)
	}
	return nil
}

func acquireEmergencyStateLock(databasePath string) (*os.File, error) {
	path := filepath.Join(filepath.Dir(databasePath), emergencyLockName)
	descriptor, err := unix.Open(
		path, unix.O_CREAT|unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0o600,
	)
	if err != nil {
		return nil, wrap("open emergency state lock", path, err)
	}
	lock := os.NewFile(uintptr(descriptor), path)
	info, err := lock.Stat()
	if err != nil {
		lock.Close()
		return nil, wrap("inspect emergency state lock", path, err)
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.Mode().IsRegular() || stat.Uid != uint32(os.Geteuid()) {
		lock.Close()
		return nil, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "use emergency state lock", Resource: path,
			Message: "emergency state lock is not an owner regular file",
		}
	}
	if info.Mode().Perm() != 0o600 {
		if err := lock.Chmod(0o600); err != nil {
			lock.Close()
			return nil, wrap("restrict emergency state lock", path, err)
		}
	}
	if err := unix.Flock(descriptor, unix.LOCK_EX); err != nil {
		lock.Close()
		return nil, wrap("lock emergency state", databasePath, err)
	}
	return lock, nil
}

func cleanupEmergencyReserveStaging(stateDirectory string) error {
	entries, err := os.ReadDir(stateDirectory)
	if err != nil {
		return wrap("list emergency reserve staging", stateDirectory, err)
	}
	for _, entry := range entries {
		if !strings.HasPrefix(entry.Name(), emergencyReserveName+"-") {
			continue
		}
		path := filepath.Join(stateDirectory, entry.Name())
		info, err := os.Lstat(path)
		if errors.Is(err, os.ErrNotExist) {
			continue
		}
		if err != nil {
			return wrap("inspect emergency reserve staging", path, err)
		}
		stat, ok := info.Sys().(*syscall.Stat_t)
		if !ok || !info.Mode().IsRegular() || stat.Uid != uint32(os.Geteuid()) {
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "clean emergency reserve staging", Resource: path,
				Message: "emergency reserve staging is not an owner regular file",
			}
		}
		if info.Mode().Perm() != 0o600 {
			if err := os.Chmod(path, 0o600); err != nil {
				return wrap("restrict emergency reserve staging", path, err)
			}
		}
		descriptor, err := unix.Open(path, unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0)
		if errors.Is(err, unix.ENOENT) {
			continue
		}
		if err != nil {
			return wrap("open emergency reserve staging", path, err)
		}
		staging := os.NewFile(uintptr(descriptor), path)
		info, err = staging.Stat()
		if err != nil {
			staging.Close()
			return wrap("inspect emergency reserve staging", path, err)
		}
		stat, ok = info.Sys().(*syscall.Stat_t)
		if !ok || !info.Mode().IsRegular() || info.Mode().Perm() != 0o600 || stat.Uid != uint32(os.Geteuid()) {
			staging.Close()
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "clean emergency reserve staging", Resource: path,
				Message: "emergency reserve staging is not an owner-only regular file",
			}
		}
		if err := unix.Flock(descriptor, unix.LOCK_EX|unix.LOCK_NB); err != nil {
			staging.Close()
			if errors.Is(err, unix.EWOULDBLOCK) || errors.Is(err, unix.EAGAIN) {
				continue
			}
			return wrap("lease emergency reserve staging", path, err)
		}
		removeErr := os.Remove(path)
		if errors.Is(removeErr, os.ErrNotExist) {
			removeErr = nil
		}
		if err := errors.Join(removeErr, staging.Close()); err != nil {
			return wrap("clean emergency reserve staging", path, err)
		}
	}
	return nil
}

func emergencyFileHasSize(path string, expectedBytes uint64) (bool, error) {
	info, err := os.Lstat(path)
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	if err != nil {
		return false, wrap("inspect emergency reserve", path, err)
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.Mode().IsRegular() || info.Mode().Perm() != 0o600 || stat.Uid != uint32(os.Geteuid()) {
		return false, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "use emergency reserve", Resource: path,
			Message: "emergency reserve is not an owner-only regular file",
		}
	}
	return info.Size() >= 0 && uint64(info.Size()) == expectedBytes, nil
}

func releaseEmergencyReserve(databasePath string, reserveBytes uint64) error {
	lock, err := acquireEmergencyStateLock(databasePath)
	if err != nil {
		return err
	}
	defer lock.Close()
	stateDirectory := filepath.Dir(databasePath)
	reservePath := filepath.Join(stateDirectory, emergencyReserveName)
	degradedPath := filepath.Join(stateDirectory, emergencyDegradedName)
	if _, degraded, err := degradedSchemaVersion(databasePath); err != nil {
		return err
	} else if degraded {
		return nil
	}
	if healthy, err := emergencyFileHasSize(reservePath, reserveBytes); err != nil {
		return err
	} else if !healthy {
		return &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "release emergency reserve", Resource: reservePath,
			Message: "emergency reserve is unavailable",
		}
	}
	marker, err := json.Marshal(struct {
		SchemaVersion int `json:"schemaVersion"`
	}{SchemaVersion: currentSchemaVersion})
	if err != nil {
		return wrap("encode degraded state marker", degradedPath, err)
	}
	descriptor, err := unix.Open(reservePath, unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0)
	if err != nil {
		return wrap("open emergency reserve", reservePath, err)
	}
	reserve := os.NewFile(uintptr(descriptor), reservePath)
	if _, err := reserve.WriteAt(marker, 0); err != nil {
		reserve.Close()
		return wrap("write degraded state marker", reservePath, err)
	}
	if err := errors.Join(reserve.Sync(), reserve.Close()); err != nil {
		return wrap("sync degraded state marker", reservePath, err)
	}
	if err := os.Rename(reservePath, degradedPath); err != nil {
		return wrap("mark state degraded", degradedPath, err)
	}
	if err := syncStateDirectory(stateDirectory); err != nil {
		return err
	}
	descriptor, err = unix.Open(degradedPath, unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0)
	if err != nil {
		return wrap("open degraded state marker", degradedPath, err)
	}
	degraded := os.NewFile(uintptr(descriptor), degradedPath)
	if err := errors.Join(degraded.Truncate(int64(len(marker))), degraded.Sync(), degraded.Close()); err != nil {
		return wrap("release emergency reserve", degradedPath, err)
	}
	return syncStateDirectory(stateDirectory)
}

func degradedSchemaVersion(databasePath string) (int, bool, error) {
	path := filepath.Join(filepath.Dir(databasePath), emergencyDegradedName)
	info, err := os.Lstat(path)
	if errors.Is(err, os.ErrNotExist) {
		return 0, false, nil
	}
	if err != nil {
		return 0, false, wrap("inspect degraded state marker", path, err)
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.Mode().IsRegular() || info.Mode().Perm() != 0o600 || stat.Uid != uint32(os.Geteuid()) ||
		info.Size() <= 0 {
		return 0, false, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "use degraded state marker", Resource: path,
			Message: "degraded state marker is invalid",
		}
	}
	descriptor, err := unix.Open(path, unix.O_RDONLY|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0)
	if err != nil {
		return 0, false, wrap("open degraded state marker", path, err)
	}
	marker := os.NewFile(uintptr(descriptor), path)
	var state struct {
		SchemaVersion int `json:"schemaVersion"`
	}
	decodeErr := json.NewDecoder(io.LimitReader(marker, 256)).Decode(&state)
	closeErr := marker.Close()
	if err := errors.Join(decodeErr, closeErr); err != nil || state.SchemaVersion <= 0 {
		return 0, false, &domain.Error{
			Code: domain.ErrorCodeUnsupportedVersion, Op: "read degraded state marker", Resource: path,
			Message: "degraded state marker has an unsupported schema",
			Err:     err,
		}
	}
	return state.SchemaVersion, true, nil
}

func advanceDegradedSchemaVersion(databasePath string, targetVersion int) error {
	lock, err := acquireEmergencyStateLock(databasePath)
	if err != nil {
		return err
	}
	defer lock.Close()
	version, degraded, err := degradedSchemaVersion(databasePath)
	if err != nil || !degraded || version >= targetVersion {
		return err
	}
	path := filepath.Join(filepath.Dir(databasePath), emergencyDegradedName)
	marker, err := json.Marshal(struct {
		SchemaVersion int `json:"schemaVersion"`
	}{SchemaVersion: targetVersion})
	if err != nil {
		return wrap("encode degraded schema version", path, err)
	}
	descriptor, err := unix.Open(path, unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0)
	if err != nil {
		return wrap("open degraded schema version", path, err)
	}
	file := os.NewFile(uintptr(descriptor), path)
	if _, err := file.WriteAt(marker, 0); err != nil {
		file.Close()
		return wrap("write degraded schema version", path, err)
	}
	if err := errors.Join(file.Sync(), file.Close()); err != nil {
		return wrap("sync degraded schema version", path, err)
	}
	return syncStateDirectory(filepath.Dir(databasePath))
}

func syncStateDirectory(path string) error {
	directory, err := os.Open(path)
	if err != nil {
		return wrap("open state directory for sync", path, err)
	}
	return errors.Join(directory.Sync(), directory.Close())
}

func PrepareStateDirectory(stateDirectory string) error {
	if err := validateCreatableStateAncestors(stateDirectory); err != nil {
		return err
	}
	if err := os.MkdirAll(stateDirectory, 0o700); err != nil {
		return wrap("create state directory", stateDirectory, err)
	}
	if err := validateStateAncestors(stateDirectory); err != nil {
		return err
	}
	return restrictStateDirectory(stateDirectory)
}

func validateCreatableStateAncestors(path string) error {
	absolute, err := filepath.Abs(path)
	if err != nil {
		return wrap("resolve state directory", path, err)
	}
	current := absolute
	for {
		if _, err := os.Lstat(current); err == nil {
			return validateStateAncestors(current)
		} else if !errors.Is(err, os.ErrNotExist) {
			return wrap("inspect state directory ancestor", current, err)
		}
		parent := filepath.Dir(current)
		if parent == current {
			return validateStateAncestors(current)
		}
		current = parent
	}
}

func validateStateAncestors(path string) error {
	absolute, err := filepath.Abs(path)
	if err != nil {
		return wrap("resolve state directory", path, err)
	}
	if err := validateAncestorChain(absolute, true); err != nil {
		return err
	}
	resolved, err := filepath.EvalSymlinks(absolute)
	if err != nil {
		return wrap("resolve state directory ancestors", path, err)
	}
	return validateAncestorChain(resolved, false)
}

func validateAncestorChain(path string, allowRootSymlinks bool) error {
	for current := path; ; current = filepath.Dir(current) {
		parent := filepath.Dir(current)
		// A namespace can report an unmapped owner for its root. No parent entry can replace that root.
		root := parent == current
		info, err := os.Lstat(current)
		if err != nil {
			return wrap("inspect state directory ancestor", current, err)
		}
		if info.Mode()&os.ModeSymlink != 0 {
			stat, ok := info.Sys().(*syscall.Stat_t)
			if !allowRootSymlinks || !ok || stat.Uid != 0 {
				return &domain.Error{
					Code: domain.ErrorCodeConflict, Op: "use state directory", Resource: current,
					Message: "state directory ancestor is an untrusted symbolic link",
				}
			}
		} else if stat, ok := info.Sys().(*syscall.Stat_t); !ok ||
			(!root && stat.Uid != 0 && stat.Uid != uint32(os.Geteuid())) {
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "use state directory", Resource: current,
				Message: "state directory ancestor has an untrusted owner",
			}
		} else if !info.IsDir() {
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "use state directory", Resource: current,
				Message: "state directory ancestor is not a directory",
			}
		} else if info.Mode().Perm()&0o022 != 0 && info.Mode()&os.ModeSticky == 0 {
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "use state directory", Resource: current,
				Message: "state directory ancestor permits untrusted replacement",
			}
		}
		if root {
			return nil
		}
	}
}

func secureDatabaseFile(path string) error {
	if err := rejectDatabaseSymlink(path); err != nil {
		return err
	}
	descriptor, err := unix.Open(
		path, unix.O_CREAT|unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0o600,
	)
	if err != nil {
		return wrap("open database securely", path, err)
	}
	file := os.NewFile(uintptr(descriptor), path)
	info, statErr := file.Stat()
	if statErr != nil {
		file.Close()
		return wrap("inspect database", path, statErr)
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.Mode().IsRegular() || stat.Uid != uint32(os.Geteuid()) {
		file.Close()
		return &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "open", Resource: path,
			Message: "database is not an owner regular file",
		}
	}
	chmodErr := file.Chmod(0o600)
	closeErr := file.Close()
	if err := errors.Join(chmodErr, closeErr); err != nil {
		return wrap("restrict database", path, err)
	}
	return nil
}

func restrictStateDirectory(path string) error {
	descriptor, err := unix.Open(path, unix.O_RDONLY|unix.O_CLOEXEC|unix.O_NOFOLLOW|unix.O_DIRECTORY, 0)
	if err != nil {
		return wrap("open state directory", path, err)
	}
	directory := os.NewFile(uintptr(descriptor), path)
	defer directory.Close()
	info, err := directory.Stat()
	if err != nil {
		return wrap("inspect state directory", path, err)
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.IsDir() || stat.Uid != uint32(os.Geteuid()) {
		return &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "use state directory", Resource: path,
			Message: "state directory is not an owner directory",
		}
	}
	if info.Mode().Perm() != 0o700 {
		if err := directory.Chmod(0o700); err != nil {
			return wrap("restrict state directory", path, err)
		}
	}
	return nil
}

func OpenReadOnly(ctx context.Context, path string) (*Store, error) {
	return openReadOnlyIn(ctx, path, os.TempDir(), domain.DefaultBudgets())
}

func OpenReadOnlyIn(ctx context.Context, path string, scratchParent string) (*Store, error) {
	return openReadOnlyIn(ctx, path, scratchParent, domain.DefaultBudgets())
}

func openReadOnlyIn(
	ctx context.Context,
	path string,
	scratchParent string,
	budgets domain.Budgets,
) (*Store, error) {
	if err := budgets.Validate(); err != nil {
		return nil, err
	}
	absolute, err := validateReadOnlySource(path)
	if err != nil {
		return nil, err
	}
	if err := validateStateAncestors(scratchParent); err != nil {
		return nil, err
	}
	if err := cleanupLegacySnapshotParent(scratchParent); err != nil {
		return nil, wrap("clean read-only database snapshots", scratchParent, err)
	}
	scratchRoot, scratchLease, err := createTemporarySnapshotRoot(
		scratchParent, absolute, budgets.MaxMaterializedSnapshots,
	)
	if err != nil {
		if domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
			return nil, err
		}
		return nil, wrap("create read-only scratch", absolute, err)
	}
	if err := cleanupSnapshotParent(scratchRoot); err != nil {
		return nil, errors.Join(
			wrap("clean read-only database snapshots", scratchRoot, err),
			cleanupTemporarySnapshotRoot(scratchRoot, scratchLease),
		)
	}
	dataSource, immutableLock, cleanupPath, cleanupLease, err := readOnlyDataSource(
		absolute, scratchRoot, budgets,
	)
	if err != nil {
		return nil, errors.Join(err, cleanupTemporarySnapshotRoot(scratchRoot, scratchLease))
	}
	store, err := connectDatabase(ctx, dataSource, absolute)
	if err != nil {
		if immutableLock != nil {
			immutableLock.Close()
		}
		cleanupReadOnlySnapshot(cleanupPath, cleanupLease)
		return nil, errors.Join(err, cleanupTemporarySnapshotRoot(scratchRoot, scratchLease))
	}
	store.readOnly = true
	store.budgets = budgets
	store.immutableLock = immutableLock
	store.readOnlyCleanup = cleanupPath
	store.readOnlyLease = cleanupLease
	store.readOnlyScratch = scratchRoot
	store.scratchLease = scratchLease
	pragmas := []string{
		"PRAGMA foreign_keys = ON",
		"PRAGMA busy_timeout = 5000",
	}
	for _, statement := range pragmas {
		if _, err := store.db.ExecContext(ctx, statement); err != nil {
			store.Close()
			return nil, wrap("configure read-only database", absolute, err)
		}
	}
	if err := store.integrityCheck(ctx); err != nil {
		store.Close()
		return nil, err
	}
	return store, nil
}

func validateReadOnlySource(path string) (string, error) {
	absolute, err := filepath.Abs(path)
	if err != nil {
		return "", wrap("resolve database", path, err)
	}
	if err := validateStateAncestors(filepath.Dir(absolute)); err != nil {
		return "", err
	}
	if err := validateReadOnlyStateDirectory(filepath.Dir(absolute)); err != nil {
		return "", err
	}
	if err := rejectDatabaseSymlink(absolute); err != nil {
		return "", err
	}
	return absolute, nil
}

func validateReadOnlyStateDirectory(path string) error {
	descriptor, err := unix.Open(path, unix.O_RDONLY|unix.O_CLOEXEC|unix.O_NOFOLLOW|unix.O_DIRECTORY, 0)
	if err != nil {
		return wrap("open read-only state directory", path, err)
	}
	directory := os.NewFile(uintptr(descriptor), path)
	defer directory.Close()
	info, err := directory.Stat()
	if err != nil {
		return wrap("inspect read-only state directory", path, err)
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.IsDir() || stat.Uid != uint32(os.Geteuid()) || info.Mode().Perm()&0o077 != 0 {
		return &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "read", Resource: path,
			Message: "state directory is not owner-only",
		}
	}
	return nil
}

func openDatabase(ctx context.Context, path string) (*Store, error) {
	return connectDatabase(ctx, path, path)
}

func connectDatabase(ctx context.Context, dataSource string, path string) (*Store, error) {
	configuredDataSource, err := connectionDataSource(dataSource)
	if err != nil {
		return nil, wrap("configure database connection", path, err)
	}
	db, err := sql.Open("sqlite", configuredDataSource)
	if err != nil {
		return nil, wrap("open database", path, err)
	}
	db.SetMaxOpenConns(1)
	db.SetMaxIdleConns(1)
	if err := db.PingContext(ctx); err != nil {
		db.Close()
		return nil, wrap("ping database", path, err)
	}
	return &Store{
		db: db, path: path, budgets: domain.DefaultBudgets(), eventRate: &eventRateLimiter{},
	}, nil
}

func connectionDataSource(dataSource string) (string, error) {
	var location *url.URL
	if strings.HasPrefix(dataSource, "file:") {
		parsed, err := url.Parse(dataSource)
		if err != nil {
			return "", err
		}
		location = parsed
	} else {
		absolute, err := filepath.Abs(dataSource)
		if err != nil {
			return "", err
		}
		location = &url.URL{Scheme: "file", Path: absolute}
	}
	query := location.Query()
	query.Set("_busy_timeout", "5000")
	location.RawQuery = query.Encode()
	return location.String(), nil
}

func existingSchemaVersion(ctx context.Context, path string, budgets domain.Budgets) (int, bool, error) {
	info, err := os.Stat(path)
	if err != nil {
		if os.IsNotExist(err) {
			return 0, false, nil
		}
		return 0, false, wrap("inspect database", path, err)
	}
	if info.Size() == 0 {
		return 0, false, nil
	}
	absolute, err := filepath.Abs(path)
	if err != nil {
		return 0, false, wrap("resolve database", path, err)
	}
	degradedVersion, degraded, err := degradedSchemaVersion(absolute)
	if err != nil {
		return 0, false, err
	}
	if degraded {
		if degradedVersion > currentSchemaVersion {
			return 0, false, unsupportedSchemaVersion(path, degradedVersion)
		}
		return degradedVersion, true, nil
	}
	recoveryState, err := hasSQLiteRecoveryState(absolute)
	if err != nil {
		return 0, false, err
	}
	if !recoveryState {
		location := &url.URL{Scheme: "file", Path: absolute}
		query := location.Query()
		query.Set("mode", "ro")
		query.Set("immutable", "1")
		location.RawQuery = query.Encode()
		store, err := connectDatabase(ctx, location.String(), absolute)
		if err != nil {
			return 0, false, err
		}
		defer store.db.Close()
		version, err := store.schemaVersion(ctx)
		if err != nil {
			return 0, false, err
		}
		return version, true, nil
	}
	startupBudgets := budgets
	startupBudgets.MaxSnapshotBytes = budgets.MaxStateBytes
	dataSource, immutableLock, cleanupPath, cleanupLease, err := readOnlyDataSource(
		absolute, filepath.Dir(absolute), startupBudgets,
	)
	if err != nil {
		return 0, false, err
	}
	if immutableLock != nil {
		defer immutableLock.Close()
	}
	defer cleanupReadOnlySnapshot(cleanupPath, cleanupLease)
	store, err := connectDatabase(ctx, dataSource, absolute)
	if err != nil {
		return 0, false, err
	}
	defer store.db.Close()
	version, err := store.schemaVersion(ctx)
	if err != nil {
		return 0, false, err
	}
	return version, true, nil
}

func hasSQLiteRecoveryState(path string) (bool, error) {
	for _, sidecarPath := range []string{path + "-wal", path + "-journal"} {
		info, err := os.Lstat(sidecarPath)
		if errors.Is(err, os.ErrNotExist) {
			continue
		}
		if err != nil {
			return false, wrap("inspect database recovery state", sidecarPath, err)
		}
		if !info.Mode().IsRegular() {
			return false, &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "inspect database recovery state", Resource: sidecarPath,
				Message: "database recovery state is not a regular file",
			}
		}
		if info.Size() > 0 {
			return true, nil
		}
	}
	return false, nil
}

func readOnlyDataSource(
	path string,
	scratchParent string,
	budgets domain.Budgets,
) (string, *os.File, string, *os.File, error) {
	location := &url.URL{Scheme: "file", Path: path}
	query := location.Query()
	query.Set("mode", "ro")
	location.RawQuery = query.Encode()
	ordinary := location.String()
	if writerRegistered(path) {
		return ordinary, nil, "", nil, nil
	}
	lock, exclusive, err := acquireImmutableSourceLock(path)
	if errors.Is(err, errReadOnlySnapshotRequired) {
		return snapshotReadOnlyDataSource(path, scratchParent, budgets)
	}
	if err != nil {
		return "", nil, "", nil, err
	}
	if !exclusive {
		return ordinary, nil, "", nil, nil
	}
	wal, err := os.Stat(path + "-wal")
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		if lock != nil {
			lock.Close()
		}
		return "", nil, "", nil, wrap("inspect database write-ahead log", path+"-wal", err)
	}
	journal, journalErr := os.Stat(path + "-journal")
	if journalErr != nil && !errors.Is(journalErr, os.ErrNotExist) {
		if lock != nil {
			lock.Close()
		}
		return "", nil, "", nil, wrap("inspect database rollback journal", path+"-journal", journalErr)
	}
	if err == nil && wal.Size() > 0 || journalErr == nil && journal.Size() > 0 {
		if lock != nil {
			lock.Close()
		}
		return snapshotReadOnlyDataSource(path, scratchParent, budgets)
	}
	query.Set("immutable", "1")
	location.RawQuery = query.Encode()
	return location.String(), lock, "", nil, nil
}

func snapshotReadOnlyDataSource(
	path string,
	scratchParent string,
	budgets domain.Budgets,
) (string, *os.File, string, *os.File, error) {
	materializationLock, err := acquireSourceMaterializationLock(path)
	if err != nil {
		return "", nil, "", nil, err
	}
	keepLock := false
	defer func() {
		if !keepLock {
			materializationLock.Close()
		}
	}()
	const attempts = 3
	for attempt := 0; attempt < attempts; attempt++ {
		snapshotBytes, err := preflightSnapshotSource(path, scratchParent, budgets)
		if err != nil {
			return "", nil, "", nil, err
		}
		directory, lease, err := createSnapshotDirectory(
			scratchParent, budgets.MaxMaterializedSnapshots,
		)
		if err != nil {
			if domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
				return "", nil, "", nil, err
			}
			return "", nil, "", nil, wrap("create read-only database snapshot", path, err)
		}
		copyPath := filepath.Join(directory, "state.sqlite3")
		remainingBytes := int64(snapshotBytes)
		copiedDatabase, err := copyAndDigestFile(path, copyPath, false, &remainingBytes)
		if err == nil {
			var copiedWAL fileDigest
			copiedWAL, err = copyAndDigestFile(path+"-wal", copyPath+"-wal", true, &remainingBytes)
			if err == nil {
				var copiedJournal fileDigest
				copiedJournal, err = copyAndDigestFile(
					path+"-journal", copyPath+"-journal", true, &remainingBytes,
				)
				currentDatabase, databaseErr := digestFile(path, false)
				currentWAL, walErr := digestFile(path+"-wal", true)
				currentJournal, journalErr := digestFile(path+"-journal", true)
				if err == nil && databaseErr == nil && walErr == nil && journalErr == nil &&
					copiedDatabase == currentDatabase && copiedWAL == currentWAL && copiedJournal == currentJournal {
					if err := recoverReadOnlySnapshot(copyPath); err != nil {
						cleanupReadOnlySnapshot(directory, lease)
						return "", nil, "", nil, err
					}
					location := &url.URL{Scheme: "file", Path: copyPath}
					query := location.Query()
					query.Set("mode", "ro")
					location.RawQuery = query.Encode()
					keepLock = true
					return location.String(), materializationLock, directory, lease, nil
				}
				if databaseErr != nil {
					err = databaseErr
				} else if walErr != nil {
					err = walErr
				} else if journalErr != nil {
					err = journalErr
				}
			}
		}
		if cleanupErr := cleanupReadOnlySnapshot(directory, lease); cleanupErr != nil && err == nil {
			err = cleanupErr
		}
		if err != nil {
			if domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
				return "", nil, "", nil, err
			}
			return "", nil, "", nil, wrap("snapshot read-only database", path, err)
		}
	}
	return "", nil, "", nil, &domain.Error{
		Code: domain.ErrorCodeConflict, Op: "snapshot", Resource: path,
		Message: "database changed during read-only snapshot",
	}
}

func acquireSourceMaterializationLock(path string) (*os.File, error) {
	for {
		lock, managed, err := openMaterializationLock(path)
		if err != nil {
			return nil, err
		}
		if err := lockMaterializationFile(lock, path); err != nil {
			return nil, err
		}
		if managed {
			return lock, nil
		}
		if _, err := os.Lstat(filepath.Join(filepath.Dir(path), materializationLockName)); errors.Is(
			err, os.ErrNotExist,
		) {
			return lock, nil
		} else if err != nil {
			lock.Close()
			return nil, wrap("inspect materialization lock", path, err)
		}
		if err := lock.Close(); err != nil {
			return nil, wrap("release legacy materialization lock", path, err)
		}
	}
}

func ensureMaterializationLock(databasePath string) error {
	path := filepath.Join(filepath.Dir(databasePath), materializationLockName)
	var legacyLock *os.File
	if _, err := os.Lstat(path); errors.Is(err, os.ErrNotExist) {
		var present bool
		legacyLock, present, err = openSnapshotSource(databasePath, true)
		if err != nil {
			return wrap("open legacy materialization lock", databasePath, err)
		}
		if present {
			if err := lockMaterializationFile(legacyLock, databasePath); err != nil {
				return err
			}
			defer legacyLock.Close()
		}
	} else if err != nil {
		return wrap("inspect materialization lock", path, err)
	}
	descriptor, err := unix.Open(
		path, unix.O_CREAT|unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0o600,
	)
	if err != nil {
		return wrap("create materialization lock", path, err)
	}
	lock := os.NewFile(uintptr(descriptor), path)
	info, statErr := lock.Stat()
	if statErr != nil {
		lock.Close()
		return wrap("inspect materialization lock", path, statErr)
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.Mode().IsRegular() || stat.Uid != uint32(os.Geteuid()) {
		lock.Close()
		return &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "use materialization lock", Resource: path,
			Message: "materialization lock is not an owner regular file",
		}
	}
	if err := errors.Join(lock.Chmod(0o600), lock.Close()); err != nil {
		return wrap("restrict materialization lock", path, err)
	}
	return nil
}

func openMaterializationLock(databasePath string) (*os.File, bool, error) {
	path := filepath.Join(filepath.Dir(databasePath), materializationLockName)
	descriptor, err := unix.Open(path, unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0)
	if errors.Is(err, unix.ENOENT) {
		lock, _, sourceErr := openSnapshotSource(databasePath, false)
		return lock, false, sourceErr
	}
	if err != nil {
		return nil, false, wrap("open materialization lock", path, err)
	}
	lock := os.NewFile(uintptr(descriptor), path)
	info, err := lock.Stat()
	if err != nil {
		lock.Close()
		return nil, false, wrap("inspect materialization lock", path, err)
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.Mode().IsRegular() || info.Mode().Perm() != 0o600 || stat.Uid != uint32(os.Geteuid()) {
		lock.Close()
		return nil, false, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "use materialization lock", Resource: path,
			Message: "materialization lock is not an owner-only regular file",
		}
	}
	return lock, true, nil
}

func lockMaterializationFile(lock *os.File, resource string) error {
	if err := unix.Flock(int(lock.Fd()), unix.LOCK_EX|unix.LOCK_NB); err != nil {
		lock.Close()
		if errors.Is(err, unix.EWOULDBLOCK) || errors.Is(err, unix.EAGAIN) {
			return &domain.Error{
				Code: domain.ErrorCodeBudgetExhausted, Op: "materialize snapshot", Resource: resource,
				Message: "source snapshot limit reached",
				Err:     err,
			}
		}
		return wrap("lock snapshot source", resource, err)
	}
	return nil
}

func preflightSnapshotSource(path string, scratchParent string, budgets domain.Budgets) (uint64, error) {
	var snapshotBytes uint64
	for index, sourcePath := range []string{path, path + "-wal", path + "-journal"} {
		source, present, err := openSnapshotSource(sourcePath, index != 0)
		if err != nil {
			return 0, wrap("inspect database snapshot source", sourcePath, err)
		}
		if !present {
			continue
		}
		info, statErr := source.Stat()
		closeErr := source.Close()
		if err := errors.Join(statErr, closeErr); err != nil {
			return 0, wrap("inspect database snapshot source", sourcePath, err)
		}
		size := uint64(info.Size())
		if size > budgets.MaxSnapshotBytes-snapshotBytes {
			return 0, &domain.Error{
				Code: domain.ErrorCodeBudgetExhausted, Op: "snapshot", Resource: path,
				Message: "snapshot byte limit exceeded",
			}
		}
		snapshotBytes += size
	}
	var filesystem unix.Statfs_t
	if err := unix.Statfs(scratchParent, &filesystem); err != nil {
		return 0, wrap("inspect snapshot filesystem capacity", scratchParent, err)
	}
	availableBytes := uint64(filesystem.Bavail) * uint64(filesystem.Bsize)
	if availableBytes < snapshotBytes || budgets.EmergencyReserveBytes > availableBytes-snapshotBytes {
		return 0, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "snapshot", Resource: scratchParent,
			Message: "snapshot filesystem reserve would be exhausted",
		}
	}
	return snapshotBytes, nil
}

func recoverReadOnlySnapshot(path string) error {
	database, err := sql.Open("sqlite", path)
	if err != nil {
		return wrap("open read-only recovery snapshot", path, err)
	}
	database.SetMaxOpenConns(1)
	database.SetMaxIdleConns(1)
	var integrity string
	if err := database.QueryRow("PRAGMA integrity_check").Scan(&integrity); err != nil {
		database.Close()
		return wrap("recover read-only database snapshot", path, err)
	}
	if integrity != "ok" {
		database.Close()
		return &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "recover snapshot", Resource: path,
			Message: "integrity check failed", Details: map[string]string{"result": integrity},
		}
	}
	if _, err := database.Exec("PRAGMA wal_checkpoint(TRUNCATE)"); err != nil {
		database.Close()
		return wrap("checkpoint read-only database snapshot", path, err)
	}
	if err := database.Close(); err != nil {
		return wrap("close read-only database snapshot", path, err)
	}
	return nil
}

func createSnapshotDirectory(parent string, maxMaterializedSnapshots uint32) (string, *os.File, error) {
	snapshotProcessState.Lock()
	defer snapshotProcessState.Unlock()
	base, err := snapshotBase(parent)
	if err != nil {
		return "", nil, err
	}
	manager, err := acquireSnapshotManager(base)
	if err != nil {
		return "", nil, err
	}
	defer manager.Close()
	if err := cleanupSnapshotDirectories(base); err != nil {
		return "", nil, err
	}
	active, err := activeMaterializations(base)
	if err != nil {
		return "", nil, err
	}
	if active >= maxMaterializedSnapshots {
		return "", nil, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "create snapshot", Resource: base,
			Message: "concurrent snapshot limit reached",
		}
	}
	lease, err := os.CreateTemp(base, "lease-")
	if err != nil {
		return "", nil, err
	}
	if err := unix.Flock(int(lease.Fd()), unix.LOCK_EX|unix.LOCK_NB); err != nil {
		lease.Close()
		os.Remove(lease.Name())
		return "", nil, err
	}
	snapshotProcessState.activeLeases[lease.Name()] = struct{}{}
	token := strings.TrimPrefix(filepath.Base(lease.Name()), "lease-")
	directory := filepath.Join(base, "snapshot-"+token)
	if err := os.Mkdir(directory, 0o700); err != nil {
		delete(snapshotProcessState.activeLeases, lease.Name())
		lease.Close()
		os.Remove(lease.Name())
		return "", nil, err
	}
	return directory, lease, nil
}

func activeMaterializations(base string) (uint32, error) {
	entries, err := os.ReadDir(base)
	if err != nil {
		return 0, err
	}
	var active uint32
	for _, entry := range entries {
		if entry.IsDir() && strings.HasPrefix(entry.Name(), "snapshot-") {
			active++
			continue
		}
		if entry.IsDir() || !strings.HasPrefix(entry.Name(), "materialization-") {
			continue
		}
		path := filepath.Join(base, entry.Name())
		if _, held := snapshotProcessState.activeLeases[path]; held {
			active++
			continue
		}
		descriptor, err := unix.Open(path, unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0)
		if err != nil {
			return 0, err
		}
		probe := os.NewFile(uintptr(descriptor), path)
		if err := unix.Flock(descriptor, unix.LOCK_EX|unix.LOCK_NB); err != nil {
			probe.Close()
			if errors.Is(err, unix.EWOULDBLOCK) || errors.Is(err, unix.EAGAIN) {
				active++
				continue
			}
			return 0, err
		}
		closeErr := probe.Close()
		removeErr := os.Remove(path)
		if err := errors.Join(closeErr, removeErr); err != nil && !errors.Is(err, os.ErrNotExist) {
			return 0, err
		}
	}
	return active, nil
}

func snapshotBase(parent string) (string, error) {
	absolute, err := filepath.Abs(parent)
	if err != nil {
		return "", err
	}
	base := filepath.Join(absolute, fmt.Sprintf(".colchis-readonly-%d", os.Geteuid()))
	if err := os.Mkdir(base, 0o700); err != nil && !errors.Is(err, os.ErrExist) {
		return "", err
	}
	info, err := os.Lstat(base)
	if err != nil {
		return "", err
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.IsDir() || info.Mode().Perm() != 0o700 || stat.Uid != uint32(os.Geteuid()) {
		return "", &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "use snapshot directory", Resource: base,
			Message: "snapshot directory is not owner-only",
		}
	}
	return base, nil
}

func cleanupSnapshotParent(parent string) error {
	snapshotProcessState.Lock()
	defer snapshotProcessState.Unlock()
	base, err := snapshotBase(parent)
	if err != nil {
		return err
	}
	manager, err := acquireSnapshotManager(base)
	if err != nil {
		return err
	}
	defer manager.Close()
	if err := cleanupSnapshotDirectories(base); err != nil {
		return err
	}
	return nil
}

func cleanupLegacySnapshotParent(parent string) error {
	base := filepath.Join(parent, fmt.Sprintf(".colchis-readonly-%d", os.Geteuid()))
	info, err := os.Lstat(base)
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	if err != nil {
		return err
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.IsDir() || info.Mode().Perm() != 0o700 || stat.Uid != uint32(os.Geteuid()) {
		return nil
	}
	snapshotProcessState.Lock()
	defer snapshotProcessState.Unlock()
	manager, err := acquireSnapshotManager(base)
	if err != nil {
		return err
	}
	defer manager.Close()
	return cleanupSnapshotDirectories(base)
}

func createTemporarySnapshotRoot(parent string, sourcePath string, limit uint32) (string, *os.File, error) {
	snapshotProcessState.Lock()
	defer snapshotProcessState.Unlock()
	base, err := temporarySnapshotManagerBase(parent)
	if err != nil {
		return "", nil, err
	}
	manager, err := acquireSnapshotManager(base)
	if err != nil {
		return "", nil, err
	}
	defer manager.Close()
	return createTemporarySnapshotRootLocked(parent, sourcePath, limit)
}

func temporarySnapshotManagerBase(parent string) (string, error) {
	absolute, err := filepath.Abs(parent)
	if err != nil {
		return "", err
	}
	base := filepath.Join(absolute, fmt.Sprintf(".colchis-snapshot-managers-%d", os.Geteuid()))
	if err := os.Mkdir(base, 0o700); err != nil && !errors.Is(err, os.ErrExist) {
		return "", err
	}
	info, err := os.Lstat(base)
	if err != nil {
		return "", err
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.IsDir() || info.Mode().Perm() != 0o700 || stat.Uid != uint32(os.Geteuid()) {
		return "", &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "use snapshot manager", Resource: base,
			Message: "snapshot manager directory is not owner-only",
		}
	}
	return base, nil
}

func createTemporarySnapshotRootReserved(parent string, sourcePath string, limit uint32) (string, *os.File, error) {
	snapshotProcessState.Lock()
	defer snapshotProcessState.Unlock()
	return createTemporarySnapshotRootLocked(parent, sourcePath, limit)
}

func createTemporarySnapshotRootLocked(parent string, sourcePath string, limit uint32) (string, *os.File, error) {
	active, err := cleanupTemporarySnapshotRoots(parent, sourcePath)
	if err != nil {
		return "", nil, err
	}
	if active >= limit {
		return "", nil, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "create snapshot", Resource: parent,
			Message: "concurrent snapshot limit reached",
		}
	}
	prefix := temporarySnapshotPrefix(sourcePath)
	root, err := os.MkdirTemp(parent, prefix)
	if err != nil {
		return "", nil, err
	}
	lease, err := os.OpenFile(filepath.Join(root, ".lease"), os.O_CREATE|os.O_EXCL|os.O_RDWR, 0o600)
	if err != nil {
		os.RemoveAll(root)
		return "", nil, err
	}
	if err := unix.Flock(int(lease.Fd()), unix.LOCK_EX|unix.LOCK_NB); err != nil {
		lease.Close()
		os.RemoveAll(root)
		return "", nil, err
	}
	snapshotProcessState.activeLeases[lease.Name()] = struct{}{}
	return root, lease, nil
}

func cleanupTemporarySnapshotRoot(root string, lease *os.File) error {
	if root == "" && lease == nil {
		return nil
	}
	snapshotProcessState.Lock()
	defer snapshotProcessState.Unlock()
	var leaseErr error
	if lease != nil {
		delete(snapshotProcessState.activeLeases, lease.Name())
		leaseErr = lease.Close()
	}
	return errors.Join(leaseErr, os.RemoveAll(root))
}

func temporarySnapshotPrefix(sourcePath string) string {
	digest := sha256.Sum256([]byte(sourcePath))
	return fmt.Sprintf(".colchis-readonly-%d-%x-", os.Geteuid(), digest)
}

func cleanupTemporarySnapshotRoots(parent string, sourcePath string) (uint32, error) {
	legacyPrefix := fmt.Sprintf(".colchis-readonly-%d-", os.Geteuid())
	prefix := temporarySnapshotPrefix(sourcePath)
	entries, err := os.ReadDir(parent)
	if err != nil {
		return 0, err
	}
	var active uint32
	for _, entry := range entries {
		legacySuffix := strings.TrimPrefix(entry.Name(), legacyPrefix)
		legacy := strings.HasPrefix(entry.Name(), legacyPrefix) && !strings.Contains(legacySuffix, "-")
		if !entry.IsDir() || !strings.HasPrefix(entry.Name(), prefix) && !legacy {
			continue
		}
		root := filepath.Join(parent, entry.Name())
		info, err := os.Lstat(root)
		if errors.Is(err, os.ErrNotExist) {
			continue
		}
		if err != nil {
			return 0, err
		}
		stat, ok := info.Sys().(*syscall.Stat_t)
		if !ok || !info.IsDir() || info.Mode().Perm() != 0o700 || stat.Uid != uint32(os.Geteuid()) {
			continue
		}
		leasePath := filepath.Join(root, ".lease")
		if _, held := snapshotProcessState.activeLeases[leasePath]; held {
			active++
			continue
		}
		descriptor, err := unix.Open(leasePath, unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0)
		if errors.Is(err, unix.ENOENT) {
			if err := os.RemoveAll(root); err != nil {
				return 0, err
			}
			continue
		}
		if err != nil {
			return 0, err
		}
		lease := os.NewFile(uintptr(descriptor), leasePath)
		leaseInfo, err := lease.Stat()
		if err != nil {
			lease.Close()
			return 0, err
		}
		leaseStat, ok := leaseInfo.Sys().(*syscall.Stat_t)
		if !ok || !leaseInfo.Mode().IsRegular() || leaseInfo.Mode().Perm() != 0o600 ||
			leaseStat.Uid != uint32(os.Geteuid()) {
			lease.Close()
			continue
		}
		if err := unix.Flock(descriptor, unix.LOCK_EX|unix.LOCK_NB); err != nil {
			lease.Close()
			if errors.Is(err, unix.EWOULDBLOCK) || errors.Is(err, unix.EAGAIN) {
				active++
				continue
			}
			return 0, err
		}
		closeErr := lease.Close()
		removeErr := os.RemoveAll(root)
		if err := errors.Join(closeErr, removeErr); err != nil {
			return 0, err
		}
	}
	return active, nil
}

func acquireSnapshotManager(base string) (*os.File, error) {
	path := filepath.Join(base, ".manager")
	descriptor, err := unix.Open(
		path, unix.O_CREAT|unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0o600,
	)
	if err != nil {
		return nil, err
	}
	manager := os.NewFile(uintptr(descriptor), path)
	info, err := manager.Stat()
	if err != nil {
		manager.Close()
		return nil, err
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.Mode().IsRegular() || info.Mode().Perm() != 0o600 || stat.Uid != uint32(os.Geteuid()) {
		manager.Close()
		return nil, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "use snapshot manager", Resource: path,
			Message: "snapshot manager is not an owner-only regular file",
		}
	}
	if err := unix.Flock(descriptor, unix.LOCK_EX); err != nil {
		manager.Close()
		return nil, err
	}
	return manager, nil
}

func cleanupSnapshotDirectories(base string) error {
	entries, err := os.ReadDir(base)
	if err != nil {
		return err
	}
	for _, entry := range entries {
		if !entry.IsDir() || !strings.HasPrefix(entry.Name(), "snapshot-") {
			continue
		}
		directory := filepath.Join(base, entry.Name())
		token := strings.TrimPrefix(entry.Name(), "snapshot-")
		leasePath := filepath.Join(base, "lease-"+token)
		if _, active := snapshotProcessState.activeLeases[leasePath]; active {
			continue
		}
		descriptor, err := unix.Open(
			leasePath, unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0,
		)
		if errors.Is(err, unix.ENOENT) {
			if err := os.RemoveAll(directory); err != nil {
				return err
			}
			continue
		}
		if err != nil {
			return err
		}
		lease := os.NewFile(uintptr(descriptor), leasePath)
		if err := unix.Flock(descriptor, unix.LOCK_EX|unix.LOCK_NB); err != nil {
			lease.Close()
			if errors.Is(err, unix.EWOULDBLOCK) || errors.Is(err, unix.EAGAIN) {
				continue
			}
			return err
		}
		removeErr := os.RemoveAll(directory)
		closeErr := lease.Close()
		leaseRemoveErr := os.Remove(leasePath)
		if errors.Is(leaseRemoveErr, os.ErrNotExist) {
			leaseRemoveErr = nil
		}
		if err := errors.Join(removeErr, closeErr, leaseRemoveErr); err != nil {
			return err
		}
	}
	entries, err = os.ReadDir(base)
	if err != nil {
		return err
	}
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasPrefix(entry.Name(), "lease-") {
			continue
		}
		leasePath := filepath.Join(base, entry.Name())
		if _, active := snapshotProcessState.activeLeases[leasePath]; active {
			continue
		}
		descriptor, err := unix.Open(leasePath, unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0)
		if err != nil {
			return err
		}
		lease := os.NewFile(uintptr(descriptor), leasePath)
		if err := unix.Flock(descriptor, unix.LOCK_EX|unix.LOCK_NB); err != nil {
			lease.Close()
			if errors.Is(err, unix.EWOULDBLOCK) || errors.Is(err, unix.EAGAIN) {
				continue
			}
			return err
		}
		closeErr := lease.Close()
		removeErr := os.Remove(leasePath)
		if errors.Is(removeErr, os.ErrNotExist) {
			removeErr = nil
		}
		if err := errors.Join(closeErr, removeErr); err != nil {
			return err
		}
	}
	return nil
}

func cleanupReadOnlySnapshot(path string, lease *os.File) error {
	if path == "" && lease == nil {
		return nil
	}
	snapshotProcessState.Lock()
	defer snapshotProcessState.Unlock()
	base := filepath.Dir(path)
	manager, managerErr := acquireSnapshotManager(base)
	if managerErr != nil {
		return managerErr
	}
	defer manager.Close()
	var removeErr error
	if path != "" {
		removeErr = os.RemoveAll(path)
	}
	var leaseErr error
	leasePath := ""
	if lease != nil {
		leasePath = lease.Name()
		delete(snapshotProcessState.activeLeases, leasePath)
		leaseErr = lease.Close()
	}
	var leaseRemoveErr error
	if leasePath != "" {
		leaseRemoveErr = os.Remove(leasePath)
		if errors.Is(leaseRemoveErr, os.ErrNotExist) {
			leaseRemoveErr = nil
		}
	}
	return errors.Join(removeErr, leaseErr, leaseRemoveErr)
}

type fileDigest struct {
	present bool
	sum     [sha256.Size]byte
}

func copyAndDigestFile(
	sourcePath string,
	targetPath string,
	optional bool,
	remainingBytes *int64,
) (fileDigest, error) {
	source, present, err := openSnapshotSource(sourcePath, optional)
	if err != nil || !present {
		return fileDigest{present: present}, err
	}
	defer source.Close()
	target, err := os.OpenFile(targetPath, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o600)
	if err != nil {
		return fileDigest{}, err
	}
	hasher := sha256.New()
	written, copyErr := io.Copy(io.MultiWriter(target, hasher), io.LimitReader(source, *remainingBytes+1))
	if copyErr == nil && written > *remainingBytes {
		copyErr = &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "copy snapshot", Resource: sourcePath,
			Message: "snapshot byte limit exceeded",
		}
	} else {
		*remainingBytes -= written
	}
	syncErr := target.Sync()
	closeErr := target.Close()
	if err := errors.Join(copyErr, syncErr, closeErr); err != nil {
		return fileDigest{}, err
	}
	var sum [sha256.Size]byte
	copy(sum[:], hasher.Sum(nil))
	return fileDigest{present: true, sum: sum}, nil
}

func digestFile(path string, optional bool) (fileDigest, error) {
	file, present, err := openSnapshotSource(path, optional)
	if err != nil || !present {
		return fileDigest{present: present}, err
	}
	defer file.Close()
	hasher := sha256.New()
	if _, err := io.Copy(hasher, file); err != nil {
		return fileDigest{}, err
	}
	var sum [sha256.Size]byte
	copy(sum[:], hasher.Sum(nil))
	return fileDigest{present: true, sum: sum}, nil
}

func openSnapshotSource(path string, optional bool) (*os.File, bool, error) {
	descriptor, err := unix.Open(path, unix.O_RDONLY|unix.O_CLOEXEC|unix.O_NOFOLLOW|unix.O_NONBLOCK, 0)
	if optional && errors.Is(err, unix.ENOENT) {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, err
	}
	file := os.NewFile(uintptr(descriptor), path)
	info, err := file.Stat()
	if err != nil {
		file.Close()
		return nil, false, err
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.Mode().IsRegular() || stat.Uid != uint32(os.Geteuid()) || info.Mode().Perm()&0o077 != 0 {
		file.Close()
		return nil, false, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "read", Resource: path,
			Message: "state file is not an owner-only regular file",
		}
	}
	return file, true, nil
}

func registerWriter(path string) {
	key, err := filepath.Abs(path)
	if err != nil {
		key = filepath.Clean(path)
	}
	writerRegistry.Lock()
	writerRegistry.paths[key]++
	writerRegistry.Unlock()
}

func unregisterWriter(path string) {
	key, err := filepath.Abs(path)
	if err != nil {
		key = filepath.Clean(path)
	}
	writerRegistry.Lock()
	if writerRegistry.paths[key] <= 1 {
		delete(writerRegistry.paths, key)
	} else {
		writerRegistry.paths[key]--
	}
	writerRegistry.Unlock()
}

func writerRegistered(path string) bool {
	key, err := filepath.Abs(path)
	if err != nil {
		key = filepath.Clean(path)
	}
	writerRegistry.Lock()
	registered := writerRegistry.paths[key] > 0
	writerRegistry.Unlock()
	return registered
}

func acquireProcessMaterialization(path string) (func(), error) {
	key, err := filepath.Abs(path)
	if err != nil {
		key = filepath.Clean(path)
	}
	writerRegistry.Lock()
	defer writerRegistry.Unlock()
	if _, active := writerRegistry.materializations[key]; active {
		return nil, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "materialize snapshot", Resource: path,
			Message: "source snapshot limit reached",
		}
	}
	writerRegistry.materializations[key] = struct{}{}
	return func() {
		writerRegistry.Lock()
		delete(writerRegistry.materializations, key)
		writerRegistry.Unlock()
	}, nil
}

func (store *Store) prepare(ctx context.Context, backupBeforeMigration bool) error {
	version, err := store.schemaVersion(ctx)
	if err != nil {
		return err
	}
	if version > currentSchemaVersion {
		return unsupportedSchemaVersion(store.path, version)
	}

	pragmas := []string{
		"PRAGMA foreign_keys = ON",
		"PRAGMA journal_mode = WAL",
		"PRAGMA synchronous = FULL",
		"PRAGMA busy_timeout = 5000",
	}
	for _, statement := range pragmas {
		if _, err := store.db.ExecContext(ctx, statement); err != nil {
			return wrap("configure database", store.path, err)
		}
	}
	if err := store.integrityCheck(ctx); err != nil {
		return err
	}
	if version == currentSchemaVersion {
		return nil
	}
	if backupBeforeMigration {
		if err := store.backup(ctx); err != nil {
			return err
		}
	}
	return store.migrate(ctx, version, nil)
}

func unsupportedSchemaVersion(path string, version int) error {
	return &domain.Error{
		Code:     domain.ErrorCodeUnsupportedVersion,
		Op:       "open",
		Resource: path,
		Message:  fmt.Sprintf("database schema %d exceeds supported schema %d", version, currentSchemaVersion),
	}
}

func rejectDatabaseSymlink(path string) error {
	if err := rejectSymlink(filepath.Dir(path), "state directory"); err != nil {
		return err
	}
	return rejectSymlink(path, "database path")
}

func rejectSymlink(path string, resourceKind string) error {
	info, err := os.Lstat(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return wrap("inspect database path", path, err)
	}
	if info.Mode()&os.ModeSymlink != 0 {
		return &domain.Error{
			Code:     domain.ErrorCodeConflict,
			Op:       "open",
			Resource: path,
			Message:  resourceKind + " is a symbolic link",
		}
	}
	return nil
}

func (store *Store) integrityCheck(ctx context.Context) error {
	var result string
	if err := store.db.QueryRowContext(ctx, "PRAGMA integrity_check").Scan(&result); err != nil {
		return wrap("check database integrity", store.path, err)
	}
	if result != "ok" {
		return &domain.Error{Code: domain.ErrorCodeInternal, Op: "integrity", Resource: store.path, Message: result}
	}
	return nil
}

func (store *Store) schemaVersion(ctx context.Context) (int, error) {
	var version int
	if err := store.db.QueryRowContext(ctx, "PRAGMA user_version").Scan(&version); err != nil {
		return 0, wrap("read schema version", store.path, err)
	}
	return version, nil
}

func (store *Store) backup(ctx context.Context) error {
	var busy int
	var logFrames int
	var checkpointedFrames int
	if err := store.db.QueryRowContext(ctx, "PRAGMA wal_checkpoint(TRUNCATE)").Scan(
		&busy,
		&logFrames,
		&checkpointedFrames,
	); err != nil {
		return wrap("checkpoint database", store.path, err)
	}
	if busy != 0 {
		return &domain.Error{
			Code:     domain.ErrorCodeConflict,
			Op:       "backup",
			Resource: store.path,
			Message:  "database checkpoint is busy",
			Details: map[string]string{
				"logFrames":          fmt.Sprint(logFrames),
				"checkpointedFrames": fmt.Sprint(checkpointedFrames),
			},
		}
	}
	source, err := os.Open(store.path)
	if err != nil {
		return wrap("open backup source", store.path, err)
	}
	defer source.Close()

	backupPath := store.path + ".backup"
	scratchDirectory, scratchLease, err := createSnapshotDirectory(
		filepath.Dir(store.path), store.budgets.MaxMaterializedSnapshots,
	)
	if err != nil {
		if domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
			return err
		}
		return wrap("create private backup staging", store.path, err)
	}
	defer cleanupReadOnlySnapshot(scratchDirectory, scratchLease)
	temporaryPath := filepath.Join(scratchDirectory, "backup.sqlite3")
	destination, err := os.OpenFile(temporaryPath, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o600)
	if err != nil {
		return wrap("create backup", temporaryPath, err)
	}
	defer func() {
		destination.Close()
	}()
	limit := int64(store.budgets.MaxSnapshotBytes)
	written, copyErr := io.Copy(destination, io.LimitReader(source, limit+1))
	if copyErr != nil {
		return wrap("copy backup", temporaryPath, copyErr)
	}
	if written > limit {
		return &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "backup", Resource: store.path,
			Message: "snapshot byte limit exceeded",
		}
	}
	if err := destination.Sync(); err != nil {
		return wrap("sync backup", temporaryPath, err)
	}
	if err := destination.Close(); err != nil {
		return wrap("close backup", temporaryPath, err)
	}
	version, err := store.schemaVersion(ctx)
	if err != nil {
		return err
	}
	if err := verifyBackup(ctx, temporaryPath, version); err != nil {
		return err
	}
	if err := os.Rename(temporaryPath, backupPath); err != nil {
		return wrap("publish backup", backupPath, err)
	}
	directoryPath := filepath.Dir(store.path)
	directory, err := os.Open(directoryPath)
	if err != nil {
		return wrap("open backup directory", directoryPath, err)
	}
	syncErr := directory.Sync()
	closeErr := directory.Close()
	if err := errors.Join(syncErr, closeErr); err != nil {
		return wrap("sync backup directory", directoryPath, err)
	}
	return nil
}

func verifyBackup(ctx context.Context, path string, expectedVersion int) error {
	absolute, err := filepath.Abs(path)
	if err != nil {
		return wrap("resolve backup", path, err)
	}
	location := &url.URL{Scheme: "file", Path: absolute}
	query := location.Query()
	query.Set("mode", "ro")
	location.RawQuery = query.Encode()
	backup, err := connectDatabase(ctx, location.String(), absolute)
	if err != nil {
		return err
	}
	defer backup.db.Close()
	if err := backup.integrityCheck(ctx); err != nil {
		return err
	}
	version, err := backup.schemaVersion(ctx)
	if err != nil {
		return err
	}
	if version != expectedVersion {
		return &domain.Error{
			Code:     domain.ErrorCodeInternal,
			Op:       "verify backup",
			Resource: path,
			Message:  fmt.Sprintf("schema version %d does not match source version %d", version, expectedVersion),
		}
	}
	return nil
}

func (store *Store) migrate(ctx context.Context, version int, afterStatement func(int) error) error {
	if version < 0 || version >= currentSchemaVersion {
		return &domain.Error{
			Code:     domain.ErrorCodeUnsupportedVersion,
			Op:       "migrate",
			Resource: store.path,
			Message:  fmt.Sprintf("no migration from schema %d", version),
		}
	}
	if err := advanceDegradedSchemaVersion(store.path, currentSchemaVersion); err != nil {
		return err
	}
	connection, err := store.db.Conn(ctx)
	if err != nil {
		return wrap("reserve migration connection", store.path, err)
	}
	connectionClosed := false
	defer func() {
		if !connectionClosed {
			connection.Close()
		}
	}()
	if _, err := connection.ExecContext(ctx, "BEGIN EXCLUSIVE"); err != nil {
		return wrap("begin migration", store.path, err)
	}
	committed := false
	defer func() {
		if !committed {
			connection.ExecContext(context.Background(), "ROLLBACK")
		}
	}()
	step := 0
	if version == 0 {
		for _, statement := range splitStatements(initialSchema) {
			if _, err := connection.ExecContext(ctx, statement); err != nil {
				return wrap("apply migration 1", store.path, err)
			}
			step++
			if afterStatement != nil {
				if err := afterStatement(step); err != nil {
					return err
				}
			}
		}
		appliedAt := time.Now().UTC().Format(time.RFC3339Nano)
		if _, err := connection.ExecContext(
			ctx, "INSERT INTO schema_migrations(version, applied_at) VALUES(?, ?)", 1, appliedAt,
		); err != nil {
			return wrap("record migration 1", store.path, err)
		}
		step++
		if afterStatement != nil {
			if err := afterStatement(step); err != nil {
				return err
			}
		}
	}
	if version < 2 {
		appliedAt := time.Now().UTC().Format(time.RFC3339Nano)
		if _, err := connection.ExecContext(
			ctx, "INSERT INTO schema_migrations(version, applied_at) VALUES(?, ?)", 2, appliedAt,
		); err != nil {
			return wrap("record migration 2", store.path, err)
		}
		step++
		if afterStatement != nil {
			if err := afterStatement(step); err != nil {
				return err
			}
		}
	}
	appliedAt := time.Now().UTC().Format(time.RFC3339Nano)
	if _, err := connection.ExecContext(
		ctx, "INSERT INTO schema_migrations(version, applied_at) VALUES(?, ?)", 3, appliedAt,
	); err != nil {
		return wrap("record migration 3", store.path, err)
	}
	step++
	if afterStatement != nil {
		if err := afterStatement(step); err != nil {
			return err
		}
	}
	if _, err := connection.ExecContext(ctx, "PRAGMA user_version = 3"); err != nil {
		return wrap("set schema version", store.path, err)
	}
	step++
	if afterStatement != nil {
		if err := afterStatement(step); err != nil {
			return err
		}
	}
	if _, err := connection.ExecContext(ctx, "COMMIT"); err != nil {
		return wrap("commit migration", store.path, err)
	}
	committed = true
	if err := connection.Close(); err != nil {
		return wrap("close migration connection", store.path, err)
	}
	connectionClosed = true
	return store.integrityCheck(ctx)
}

func splitStatements(script string) []string {
	parts := strings.Split(script, ";")
	statements := make([]string, 0, len(parts))
	for _, part := range parts {
		if statement := strings.TrimSpace(part); statement != "" {
			statements = append(statements, statement)
		}
	}
	return statements
}

func (store *Store) Close() error {
	databaseErr := store.db.Close()
	var lockErr error
	if store.immutableLock != nil {
		lockErr = store.immutableLock.Close()
		store.immutableLock = nil
	}
	cleanupErr := cleanupReadOnlySnapshot(store.readOnlyCleanup, store.readOnlyLease)
	store.readOnlyCleanup = ""
	store.readOnlyLease = nil
	scratchErr := cleanupTemporarySnapshotRoot(store.readOnlyScratch, store.scratchLease)
	store.readOnlyScratch = ""
	store.scratchLease = nil
	if store.writerRegistered {
		unregisterWriter(store.path)
		store.writerRegistered = false
	}
	return errors.Join(databaseErr, lockErr, cleanupErr, scratchErr)
}

func ExportReadOnly(ctx context.Context, sourcePath string, targetPath string) error {
	release, err := acquireProcessMaterialization(sourcePath)
	if err != nil {
		return err
	}
	defer release()
	absoluteTarget, err := filepath.Abs(targetPath)
	if err != nil {
		return wrap("resolve database export", targetPath, err)
	}
	targetParent := filepath.Dir(absoluteTarget)
	if err := validateStateAncestors(targetParent); err != nil {
		return err
	}
	store, err := openReadOnlyIn(
		ctx, sourcePath, targetParent, domain.DefaultBudgets(),
	)
	if err != nil {
		return err
	}
	if store.immutableLock == nil {
		store.immutableLock, err = acquireSourceMaterializationLock(sourcePath)
		if err != nil {
			return errors.Join(err, store.Close())
		}
	}
	exportErr := store.exportTo(ctx, absoluteTarget)
	return errors.Join(exportErr, store.Close())
}

func (store *Store) Transaction(ctx context.Context, apply func(*Tx) error) error {
	if store.readOnly {
		return &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "write", Resource: store.path, Message: "database is read-only",
		}
	}
	transaction, err := store.db.BeginTx(ctx, nil)
	if err != nil {
		return wrap("begin transaction", store.path, err)
	}
	transactionState := &Tx{
		tx: transaction, path: store.path, budgets: store.budgets, eventRate: store.eventRate,
		emergencyReserve: store.emergencyReserve,
	}
	if err := apply(transactionState); err != nil {
		rollbackErr := transaction.Rollback()
		reserveErr := transactionState.restoreEmergencyReserve()
		if rollbackErr != nil || reserveErr != nil {
			return wrap("rollback transaction", store.path, errors.Join(err, rollbackErr, reserveErr))
		}
		return err
	}
	if err := transaction.Commit(); err != nil {
		return wrap("commit transaction", store.path, errors.Join(err, transactionState.restoreEmergencyReserve()))
	}
	if err := transactionState.restoreEmergencyReserve(); err != nil {
		// A committed terminal state outranks replenishment, so the marker blocks later dispatch.
		return nil
	}
	return nil
}

func (transaction *Tx) restoreEmergencyReserve() error {
	if !transaction.reserveReleased {
		return nil
	}
	return ensureEmergencyReserve(transaction.path, transaction.budgets.EmergencyReserveBytes)
}

type TableInspection struct {
	Name string `json:"name"`
	Rows uint64 `json:"rows"`
}

type Inspection struct {
	Path            string             `json:"path"`
	SchemaVersion   int                `json:"schemaVersion"`
	Integrity       string             `json:"integrity"`
	Degraded        bool               `json:"degraded"`
	ByteSize        uint64             `json:"byteSize"`
	LastEventCursor domain.EventCursor `json:"lastEventCursor"`
	Tables          []TableInspection  `json:"tables"`
}

func (store *Store) Inspect(ctx context.Context) (Inspection, error) {
	transaction, err := store.db.BeginTx(ctx, &sql.TxOptions{ReadOnly: true})
	if err != nil {
		return Inspection{}, wrap("begin database inspection", store.path, err)
	}
	defer transaction.Rollback()
	var version int
	if err := transaction.QueryRowContext(ctx, "PRAGMA user_version").Scan(&version); err != nil {
		return Inspection{}, wrap("read schema version", store.path, err)
	}
	info, err := os.Stat(store.path)
	if err != nil {
		return Inspection{}, wrap("inspect database file", store.path, err)
	}
	rows, err := transaction.QueryContext(
		ctx,
		`SELECT name FROM sqlite_schema
         WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
         ORDER BY name`,
	)
	if err != nil {
		return Inspection{}, wrap("list database tables", store.path, err)
	}
	var names []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			rows.Close()
			return Inspection{}, wrap("scan database table", store.path, err)
		}
		names = append(names, name)
	}
	if err := rows.Err(); err != nil {
		rows.Close()
		return Inspection{}, wrap("iterate database tables", store.path, err)
	}
	if err := rows.Close(); err != nil {
		return Inspection{}, wrap("close database tables", store.path, err)
	}

	inspection := Inspection{
		Path:          store.path,
		SchemaVersion: version,
		Integrity:     "ok",
		ByteSize:      uint64(info.Size()),
		Tables:        make([]TableInspection, 0, len(names)),
	}
	if _, degraded, err := degradedSchemaVersion(store.path); err != nil {
		return Inspection{}, err
	} else {
		inspection.Degraded = degraded
	}
	for _, name := range names {
		quoted := `"` + strings.ReplaceAll(name, `"`, `""`) + `"`
		var count int64
		if err := transaction.QueryRowContext(ctx, "SELECT COUNT(*) FROM "+quoted).Scan(&count); err != nil {
			return Inspection{}, wrap("count database table", name, err)
		}
		if count < 0 {
			return Inspection{}, &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "count", Resource: name, Message: "row count is negative",
			}
		}
		inspection.Tables = append(inspection.Tables, TableInspection{Name: name, Rows: uint64(count)})
		if name == "events" {
			var cursor int64
			if err := transaction.QueryRowContext(ctx, "SELECT COALESCE(MAX(cursor), 0) FROM events").Scan(&cursor); err != nil {
				return Inspection{}, wrap("read event cursor", store.path, err)
			}
			if cursor < 0 {
				return Inspection{}, &domain.Error{
					Code: domain.ErrorCodeInternal, Op: "inspect", Resource: store.path, Message: "event cursor is negative",
				}
			}
			inspection.LastEventCursor = domain.EventCursor(cursor)
		}
	}
	if err := transaction.Commit(); err != nil {
		return Inspection{}, wrap("commit database inspection", store.path, err)
	}
	return inspection, nil
}

func (store *Store) ExportTo(ctx context.Context, targetPath string) error {
	store.exportMu.Lock()
	defer store.exportMu.Unlock()
	release, err := acquireProcessMaterialization(store.path)
	if err != nil {
		return err
	}
	defer release()
	if store.immutableLock == nil {
		sourceLease, err := acquireSourceMaterializationLock(store.path)
		if err != nil {
			return err
		}
		defer sourceLease.Close()
	}
	return store.exportTo(ctx, targetPath)
}

func (store *Store) exportTo(ctx context.Context, targetPath string) error {
	if targetPath == "" {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "export", Resource: "export path", Message: "path is empty",
		}
	}
	absoluteTarget, err := filepath.Abs(targetPath)
	if err != nil {
		return wrap("resolve database export", targetPath, err)
	}
	if absoluteTarget == store.path {
		return &domain.Error{
			Code: domain.ErrorCodeConflict, Op: "export", Resource: absoluteTarget,
			Message: "export path matches the source database",
		}
	}
	parent, err := os.Stat(filepath.Dir(absoluteTarget))
	if err != nil {
		return wrap("inspect database export directory", filepath.Dir(absoluteTarget), err)
	}
	if !parent.IsDir() {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "export", Resource: filepath.Dir(absoluteTarget),
			Message: "export parent is not a directory",
		}
	}
	if err := validateStateAncestors(filepath.Dir(absoluteTarget)); err != nil {
		return err
	}
	version, err := store.schemaVersion(ctx)
	if err != nil {
		return err
	}
	if _, err := os.Lstat(absoluteTarget); err == nil {
		return &domain.Error{
			Code: domain.ErrorCodeConflict, Op: "export", Resource: absoluteTarget,
			Message: "export path already exists",
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return wrap("inspect database export", absoluteTarget, err)
	}
	if err := cleanupLegacySnapshotParent(filepath.Dir(absoluteTarget)); err != nil {
		return wrap("clean legacy database export staging", absoluteTarget, err)
	}
	scratchDirectory, scratchLease, err := createTemporarySnapshotRootReserved(
		filepath.Dir(absoluteTarget), store.path, store.budgets.MaxMaterializedSnapshots,
	)
	if err != nil {
		return wrap("create private database export staging", absoluteTarget, err)
	}
	defer cleanupTemporarySnapshotRoot(scratchDirectory, scratchLease)
	temporaryPath := filepath.Join(scratchDirectory, "export.sqlite3")

	connection, err := store.db.Conn(ctx)
	if err != nil {
		return wrap("reserve database export connection", store.path, err)
	}
	defer connection.Close()
	var pageCount uint64
	var pageSize uint64
	if err := connection.QueryRowContext(ctx, "PRAGMA page_count").Scan(&pageCount); err != nil {
		return wrap("read database export page count", store.path, err)
	}
	if err := connection.QueryRowContext(ctx, "PRAGMA page_size").Scan(&pageSize); err != nil {
		return wrap("read database export page size", store.path, err)
	}
	if pageSize != 0 && pageCount > store.budgets.MaxSnapshotBytes/pageSize {
		return &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "export", Resource: store.path,
			Message: "snapshot byte limit exceeded",
		}
	}
	estimatedBytes := pageCount * pageSize
	var filesystem unix.Statfs_t
	if err := unix.Statfs(filepath.Dir(absoluteTarget), &filesystem); err != nil {
		return wrap("inspect database export capacity", absoluteTarget, err)
	}
	availableBytes := uint64(filesystem.Bavail) * uint64(filesystem.Bsize)
	if availableBytes < estimatedBytes ||
		store.budgets.EmergencyReserveBytes > availableBytes-estimatedBytes {
		return &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "export", Resource: absoluteTarget,
			Message: "export filesystem reserve would be exhausted",
		}
	}
	if _, err := connection.ExecContext(ctx, "VACUUM INTO ?", temporaryPath); err != nil {
		return wrap("copy database export", store.path, err)
	}
	exportInfo, err := os.Stat(temporaryPath)
	if err != nil {
		return wrap("inspect database export", temporaryPath, err)
	}
	if uint64(exportInfo.Size()) > store.budgets.MaxSnapshotBytes {
		return &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "export", Resource: store.path,
			Message: "snapshot byte limit exceeded",
		}
	}
	if err := verifyBackup(ctx, temporaryPath, version); err != nil {
		return err
	}
	if err := os.Chmod(temporaryPath, 0o600); err != nil {
		return wrap("restrict database export", temporaryPath, err)
	}
	temporary, err := os.Open(temporaryPath)
	if err != nil {
		return wrap("open database export", temporaryPath, err)
	}
	if err := temporary.Sync(); err != nil {
		temporary.Close()
		return wrap("sync database export", temporaryPath, err)
	}
	if err := temporary.Close(); err != nil {
		return wrap("close database export", temporaryPath, err)
	}
	if err := publishFileNoReplace(temporaryPath, absoluteTarget); err != nil {
		return wrap("publish database export", absoluteTarget, err)
	}
	directory, err := os.Open(filepath.Dir(absoluteTarget))
	if err != nil {
		return wrap("open database export directory", filepath.Dir(absoluteTarget), err)
	}
	if err := directory.Sync(); err != nil {
		directory.Close()
		return wrap("sync database export directory", filepath.Dir(absoluteTarget), err)
	}
	if err := directory.Close(); err != nil {
		return wrap("close database export directory", filepath.Dir(absoluteTarget), err)
	}
	return nil
}

func (store *Store) AcceptCommand(
	ctx context.Context,
	principal string,
	request domain.CommandRequest,
) (domain.CommandRecord, bool, error) {
	if principal == "" {
		return domain.CommandRecord{}, false, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "command principal", Message: "principal is empty",
		}
	}
	if err := request.Validate(); err != nil {
		return domain.CommandRecord{}, false, err
	}
	var accepted domain.CommandRecord
	var created bool
	err := store.Transaction(ctx, func(transaction *Tx) error {
		existing, found, err := transaction.commandByIdempotency(ctx, principal, request.IdempotencyKey)
		if err != nil {
			return err
		}
		if found {
			if !commandMatches(existing, principal, request) {
				return &domain.Error{
					Code: domain.ErrorCodeConflict, Op: "accept", Resource: request.IdempotencyKey,
					Message: "idempotency key belongs to another command",
				}
			}
			accepted = existing
			return nil
		}
		if _, found, err := transaction.commandByID(ctx, request.ID); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "accept", Resource: string(request.ID),
				Message: "command identifier already exists",
			}
		}
		now := time.Now().UTC()
		accepted = domain.CommandRecord{
			Metadata: domain.RecordMetadata{
				SchemaVersion: domain.CurrentRecordSchemaVersion, ResourceVersion: 1, CreatedAt: now, UpdatedAt: now,
			},
			ID:              request.ID,
			IdempotencyKey:  request.IdempotencyKey,
			Principal:       principal,
			Kind:            request.Kind,
			ExpectedVersion: request.ExpectedVersion,
			State:           domain.CommandStateAccepted,
			Payload:         request.Payload,
		}
		encoded, err := json.Marshal(accepted)
		if err != nil {
			return wrap("encode command", string(request.ID), err)
		}
		eventPayload, err := json.Marshal(struct {
			CommandID domain.CommandID `json:"commandId"`
			Kind      string           `json:"kind"`
		}{CommandID: request.ID, Kind: request.Kind})
		if err != nil {
			return wrap("encode command event", string(request.ID), err)
		}
		admissionBytes, err := transaction.commandAdmissionBytes(ctx, encoded, eventPayload)
		if err != nil {
			return err
		}
		if transaction.emergencyReserve && admissionBytes > transaction.budgets.EmergencyReserveBytes {
			return &domain.Error{
				Code: domain.ErrorCodeBudgetExhausted, Op: "accept command", Resource: string(request.ID),
				Message: "command terminal state exceeds the emergency reserve",
			}
		}
		if err := transaction.reserveStateCapacity(ctx, admissionBytes, false); err != nil {
			return err
		}
		if err := transaction.putRecord(ctx, "command", string(request.ID), accepted.Metadata, encoded); err != nil {
			return err
		}
		idempotencyID := commandIdempotencyID(principal, request.IdempotencyKey)
		if err := transaction.putRecord(ctx, "command-idempotency", idempotencyID, accepted.Metadata, encoded); err != nil {
			return err
		}
		if _, err := transaction.AppendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion,
			OccurredAt:    now,
			Aggregate:     domain.ResourceReference{Kind: "command", ID: string(request.ID)},
			Type:          "command.accepted",
			Payload:       eventPayload,
		}); err != nil {
			return err
		}
		created = true
		return nil
	})
	return accepted, created, err
}

func (store *Store) ClaimCommand(
	ctx context.Context,
	id domain.CommandID,
) (domain.CommandRecord, bool, error) {
	return store.transitionCommand(ctx, id, domain.CommandStateAccepted, domain.CommandStateRunning)
}

func (store *Store) RecoverRunningCommands(ctx context.Context) ([]domain.CommandRecord, error) {
	rows, err := store.db.QueryContext(
		ctx,
		"SELECT payload FROM records WHERE kind = 'command' ORDER BY id",
	)
	if err != nil {
		return nil, wrap("read running commands", store.path, err)
	}
	var running []domain.CommandID
	for rows.Next() {
		var payload []byte
		if err := rows.Scan(&payload); err != nil {
			rows.Close()
			return nil, wrap("scan running command", store.path, err)
		}
		var record domain.CommandRecord
		if err := json.Unmarshal(payload, &record); err != nil {
			rows.Close()
			return nil, wrap("decode running command", store.path, err)
		}
		if record.State == domain.CommandStateRunning {
			running = append(running, record.ID)
		}
	}
	if err := rows.Err(); err != nil {
		rows.Close()
		return nil, wrap("iterate running commands", store.path, err)
	}
	if err := rows.Close(); err != nil {
		return nil, wrap("close running commands", store.path, err)
	}

	recovered := make([]domain.CommandRecord, 0, len(running))
	for _, id := range running {
		record, changed, err := store.transitionCommand(
			ctx,
			id,
			domain.CommandStateRunning,
			domain.CommandStateIndeterminate,
		)
		if err != nil {
			return nil, err
		}
		if changed {
			recovered = append(recovered, record)
		}
	}
	return recovered, nil
}

func (store *Store) FinishCommand(
	ctx context.Context,
	id domain.CommandID,
	state domain.CommandState,
	commandResult ...json.RawMessage,
) (domain.CommandRecord, error) {
	if state != domain.CommandStateSucceeded && state != domain.CommandStateFailed &&
		state != domain.CommandStateIndeterminate {
		return domain.CommandRecord{}, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "finish", Resource: string(id),
			Message: "command finish state must be succeeded, failed, or indeterminate",
		}
	}
	if len(commandResult) > 1 || len(commandResult) == 1 && !json.Valid(commandResult[0]) {
		return domain.CommandRecord{}, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "finish", Resource: string(id),
			Message: "command result must be one valid JSON value",
		}
	}
	record, changed, err := store.transitionCommand(ctx, id, domain.CommandStateRunning, state, commandResult...)
	if err != nil {
		return domain.CommandRecord{}, err
	}
	if !changed {
		return record, &domain.Error{
			Code: domain.ErrorCodeConflict, Op: "finish", Resource: string(id),
			Message: "command is not running",
		}
	}
	return record, nil
}

func (store *Store) transitionCommand(
	ctx context.Context,
	id domain.CommandID,
	from domain.CommandState,
	to domain.CommandState,
	commandResult ...json.RawMessage,
) (domain.CommandRecord, bool, error) {
	var result domain.CommandRecord
	var changed bool
	err := store.Transaction(ctx, func(transaction *Tx) error {
		record, found, err := transaction.commandByID(ctx, id)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "transition", Resource: string(id), Message: "command does not exist",
			}
		}
		result = record
		if record.State != from {
			return nil
		}
		if to == domain.CommandStateSucceeded || to == domain.CommandStateFailed ||
			to == domain.CommandStateIndeterminate {
			if err := transaction.releaseEmergencyReserve(); err != nil {
				return err
			}
		}
		now := time.Now().UTC()
		result.State = to
		if len(commandResult) == 1 {
			result.Result = append(json.RawMessage(nil), commandResult[0]...)
		}
		result.Metadata.ResourceVersion++
		result.Metadata.UpdatedAt = now
		encoded, err := json.Marshal(result)
		if err != nil {
			return wrap("encode command transition", string(id), err)
		}
		if err := transaction.updateRecord(ctx, "command", string(id), record.Metadata.ResourceVersion, result.Metadata, encoded); err != nil {
			return err
		}
		idempotencyID := commandIdempotencyID(record.Principal, record.IdempotencyKey)
		if err := transaction.updateRecord(
			ctx,
			"command-idempotency",
			idempotencyID,
			record.Metadata.ResourceVersion,
			result.Metadata,
			encoded,
		); err != nil {
			return err
		}
		eventPayload, err := json.Marshal(struct {
			CommandID domain.CommandID    `json:"commandId"`
			State     domain.CommandState `json:"state"`
		}{CommandID: id, State: to})
		if err != nil {
			return wrap("encode command transition event", string(id), err)
		}
		if _, err := transaction.appendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion,
			OccurredAt:    now,
			Aggregate:     domain.ResourceReference{Kind: "command", ID: string(id)},
			Type:          "command." + string(to),
			Payload:       eventPayload,
		}, to != domain.CommandStateRunning); err != nil {
			return err
		}
		changed = true
		return nil
	})
	return result, changed, err
}

func (transaction *Tx) commandByIdempotency(
	ctx context.Context,
	principal string,
	key string,
) (domain.CommandRecord, bool, error) {
	return transaction.commandRecord(ctx, "command-idempotency", commandIdempotencyID(principal, key))
}

func (transaction *Tx) commandByID(
	ctx context.Context,
	id domain.CommandID,
) (domain.CommandRecord, bool, error) {
	return transaction.commandRecord(ctx, "command", string(id))
}

func (transaction *Tx) commandRecord(
	ctx context.Context,
	kind string,
	id string,
) (domain.CommandRecord, bool, error) {
	var payload []byte
	err := transaction.tx.QueryRowContext(
		ctx,
		"SELECT payload FROM records WHERE kind = ? AND id = ?",
		kind,
		id,
	).Scan(&payload)
	if errors.Is(err, sql.ErrNoRows) {
		return domain.CommandRecord{}, false, nil
	}
	if err != nil {
		return domain.CommandRecord{}, false, wrap("read command", id, err)
	}
	var record domain.CommandRecord
	if err := json.Unmarshal(payload, &record); err != nil {
		return domain.CommandRecord{}, false, wrap("decode command", id, err)
	}
	return record, true, nil
}

func (transaction *Tx) putRecord(
	ctx context.Context,
	kind string,
	id string,
	metadata domain.RecordMetadata,
	payload []byte,
) error {
	_, err := transaction.tx.ExecContext(
		ctx,
		`INSERT INTO records(kind, id, schema_version, resource_version, payload, created_at, updated_at)
		 VALUES(?, ?, ?, ?, ?, ?, ?)`,
		kind,
		id,
		metadata.SchemaVersion,
		metadata.ResourceVersion,
		payload,
		metadata.CreatedAt.Format(time.RFC3339Nano),
		metadata.UpdatedAt.Format(time.RFC3339Nano),
	)
	if err != nil {
		return wrap("write record", kind+":"+id, err)
	}
	return nil
}

func (transaction *Tx) updateRecord(
	ctx context.Context,
	kind string,
	id string,
	expectedVersion domain.ResourceVersion,
	metadata domain.RecordMetadata,
	payload []byte,
) error {
	result, err := transaction.tx.ExecContext(
		ctx,
		`UPDATE records
		 SET schema_version = ?, resource_version = ?, payload = ?, updated_at = ?
		 WHERE kind = ? AND id = ? AND resource_version = ?`,
		metadata.SchemaVersion,
		metadata.ResourceVersion,
		payload,
		metadata.UpdatedAt.Format(time.RFC3339Nano),
		kind,
		id,
		expectedVersion,
	)
	if err != nil {
		return wrap("update record", kind+":"+id, err)
	}
	rows, err := result.RowsAffected()
	if err != nil {
		return wrap("count updated records", kind+":"+id, err)
	}
	if rows != 1 {
		return &domain.Error{
			Code: domain.ErrorCodeConflict, Op: "update", Resource: kind + ":" + id,
			Message: "record version changed",
		}
	}
	return nil
}

func commandIdempotencyID(principal string, key string) string {
	digest := sha256.Sum256([]byte(principal + "\x00" + key))
	return fmt.Sprintf("%x", digest[:])
}

func commandMatches(record domain.CommandRecord, principal string, request domain.CommandRequest) bool {
	if record.ID != request.ID || record.IdempotencyKey != request.IdempotencyKey ||
		record.Principal != principal || record.Kind != request.Kind ||
		!resourceVersionsEqual(record.ExpectedVersion, request.ExpectedVersion) {
		return false
	}
	var recordPayload bytes.Buffer
	var requestPayload bytes.Buffer
	if json.Compact(&recordPayload, record.Payload) != nil || json.Compact(&requestPayload, request.Payload) != nil {
		return false
	}
	return bytes.Equal(recordPayload.Bytes(), requestPayload.Bytes())
}

func resourceVersionsEqual(first *domain.ResourceVersion, second *domain.ResourceVersion) bool {
	if first == nil || second == nil {
		return first == nil && second == nil
	}
	return *first == *second
}

func (store *Store) AppendEvent(ctx context.Context, event domain.EventEnvelope) (domain.EventEnvelope, error) {
	var appended domain.EventEnvelope
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var appendErr error
		appended, appendErr = transaction.AppendEvent(ctx, event)
		return appendErr
	})
	return appended, err
}

func (transaction *Tx) AppendEvent(ctx context.Context, event domain.EventEnvelope) (domain.EventEnvelope, error) {
	return transaction.appendEvent(ctx, event, false)
}

func (transaction *Tx) appendEvent(
	ctx context.Context,
	event domain.EventEnvelope,
	critical bool,
) (domain.EventEnvelope, error) {
	if err := event.ValidateForAppend(); err != nil {
		return domain.EventEnvelope{}, err
	}
	metadata, err := json.Marshal(event.Metadata)
	if err != nil {
		return domain.EventEnvelope{}, wrap("encode event metadata", event.Type, err)
	}
	eventBytes := uint64(len(event.Payload) + len(metadata))
	if eventBytes > transaction.budgets.MaxEventBytes {
		return domain.EventEnvelope{}, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "append event", Resource: event.Type,
			Message: "event byte limit exceeded",
		}
	}
	if err := transaction.reserveEventCapacity(ctx, eventBytes, critical); err != nil {
		return domain.EventEnvelope{}, err
	}
	result, err := transaction.tx.ExecContext(
		ctx,
		`INSERT INTO events(
            schema_version, occurred_at, aggregate_kind, aggregate_id, event_type, payload, metadata
        ) VALUES(?, ?, ?, ?, ?, ?, ?)`,
		event.SchemaVersion,
		event.OccurredAt.UTC().Format(time.RFC3339Nano),
		event.Aggregate.Kind,
		event.Aggregate.ID,
		event.Type,
		[]byte(event.Payload),
		metadata,
	)
	if err != nil {
		return domain.EventEnvelope{}, wrap("append event", event.Type, err)
	}
	cursor, err := result.LastInsertId()
	if err != nil {
		return domain.EventEnvelope{}, wrap("read event cursor", event.Type, err)
	}
	event.Cursor = domain.EventCursor(cursor)
	return event, nil
}

func (transaction *Tx) reserveEventCapacity(ctx context.Context, eventBytes uint64, critical bool) error {
	if !critical && !transaction.eventRate.reserve(transaction.budgets.MaxEventsPerSecond) {
		return &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "append event", Resource: transaction.path,
			Message: "event rate limit reached",
		}
	}
	var pageSize uint64
	if err := transaction.tx.QueryRowContext(ctx, "PRAGMA page_size").Scan(&pageSize); err != nil {
		return wrap("read database page size", transaction.path, err)
	}
	overheadBytes := pageSize * 8
	if eventBytes > (^uint64(0)-overheadBytes)/2 {
		return &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "append event", Resource: transaction.path,
			Message: "event storage estimate exceeds supported size",
		}
	}
	return transaction.reserveStateCapacity(ctx, eventBytes*2+overheadBytes, critical)
}

func (transaction *Tx) commandAdmissionBytes(
	ctx context.Context,
	encoded []byte,
	eventPayload []byte,
) (uint64, error) {
	var pageSize uint64
	if err := transaction.tx.QueryRowContext(ctx, "PRAGMA page_size").Scan(&pageSize); err != nil {
		return 0, wrap("read database page size", transaction.path, err)
	}
	payloadBytes := uint64(len(encoded))*2 + uint64(len(eventPayload))
	overheadBytes := pageSize * 32
	if payloadBytes > (^uint64(0)-overheadBytes)/2 {
		return 0, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "accept command", Resource: transaction.path,
			Message: "command storage estimate exceeds supported size",
		}
	}
	return payloadBytes*2 + overheadBytes, nil
}

func (transaction *Tx) releaseEmergencyReserve() error {
	if !transaction.emergencyReserve || transaction.reserveReleased {
		return nil
	}
	if err := releaseEmergencyReserve(transaction.path, transaction.budgets.EmergencyReserveBytes); err != nil {
		return err
	}
	transaction.reserveReleased = true
	return nil
}

func (transaction *Tx) reserveStateCapacity(ctx context.Context, writeBytes uint64, critical bool) error {
	if critical {
		if err := transaction.releaseEmergencyReserve(); err != nil {
			return err
		}
	} else if transaction.emergencyReserve {
		if healthy, err := emergencyFileHasSize(
			filepath.Join(filepath.Dir(transaction.path), emergencyReserveName),
			transaction.budgets.EmergencyReserveBytes,
		); err != nil {
			return err
		} else if !healthy {
			return &domain.Error{
				Code: domain.ErrorCodeBudgetExhausted, Op: "append event", Resource: transaction.path,
				Message: "emergency reserve is unavailable",
			}
		}
	}
	var pageCount uint64
	var pageSize uint64
	if err := transaction.tx.QueryRowContext(ctx, "PRAGMA page_count").Scan(&pageCount); err != nil {
		return wrap("read database page count", transaction.path, err)
	}
	if err := transaction.tx.QueryRowContext(ctx, "PRAGMA page_size").Scan(&pageSize); err != nil {
		return wrap("read database page size", transaction.path, err)
	}
	usableStateBytes := transaction.budgets.MaxStateBytes
	if !critical {
		usableStateBytes -= transaction.budgets.EmergencyReserveBytes
	}
	physicalBytes, err := physicalStateBytes(transaction.path)
	if err != nil {
		return err
	}
	if writeBytes > usableStateBytes || physicalBytes > usableStateBytes-writeBytes ||
		(pageSize != 0 && pageCount > (usableStateBytes-writeBytes)/pageSize) {
		return &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "append event", Resource: transaction.path,
			Message: "state byte limit reached",
		}
	}
	var filesystem unix.Statfs_t
	if err := unix.Statfs(filepath.Dir(transaction.path), &filesystem); err != nil {
		return wrap("inspect state filesystem capacity", transaction.path, err)
	}
	available := uint64(filesystem.Bavail) * uint64(filesystem.Bsize)
	required := writeBytes
	if !critical && !transaction.emergencyReserve {
		required += transaction.budgets.EmergencyReserveBytes
	}
	if available < required {
		return &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "append event", Resource: transaction.path,
			Message: "emergency write reserve reached",
		}
	}
	return nil
}

func physicalStateBytes(path string) (uint64, error) {
	var total uint64
	for _, statePath := range []string{path, path + "-wal", path + "-journal", path + "-shm"} {
		info, err := os.Lstat(statePath)
		if errors.Is(err, os.ErrNotExist) {
			continue
		}
		if err != nil {
			return 0, wrap("inspect physical state", statePath, err)
		}
		if !info.Mode().IsRegular() || info.Size() < 0 {
			return 0, &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "inspect physical state", Resource: statePath,
				Message: "state component is not a regular file",
			}
		}
		size := uint64(info.Size())
		if size > ^uint64(0)-total {
			return 0, &domain.Error{
				Code: domain.ErrorCodeBudgetExhausted, Op: "inspect physical state", Resource: path,
				Message: "physical state size exceeds supported capacity",
			}
		}
		total += size
	}
	objectBytes, err := physicalDirectoryBytes(
		filepath.Join(filepath.Dir(path), workspaceObjectStoreName),
	)
	if err != nil {
		return 0, err
	}
	if objectBytes > ^uint64(0)-total {
		return 0, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "inspect physical state", Resource: path,
			Message: "physical state size exceeds supported capacity",
		}
	}
	return total + objectBytes, nil
}

func physicalDirectoryBytes(root string) (uint64, error) {
	info, err := os.Lstat(root)
	if errors.Is(err, os.ErrNotExist) {
		return 0, nil
	}
	if err != nil {
		return 0, wrap("inspect physical state", root, err)
	}
	if info.Mode()&os.ModeSymlink != 0 || !info.IsDir() {
		return 0, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "inspect physical state", Resource: root,
			Message: "state directory is not a direct directory",
		}
	}
	var total uint64
	err = filepath.WalkDir(root, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return wrap("inspect physical state", path, walkErr)
		}
		if entry.IsDir() {
			return nil
		}
		entryInfo, err := entry.Info()
		if err != nil {
			return wrap("inspect physical state", path, err)
		}
		if entryInfo.Mode()&os.ModeSymlink != 0 || !entryInfo.Mode().IsRegular() || entryInfo.Size() < 0 {
			return &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "inspect physical state", Resource: path,
				Message: "state directory contains an unsupported entry",
			}
		}
		size := uint64(entryInfo.Size())
		if size > ^uint64(0)-total {
			return &domain.Error{
				Code: domain.ErrorCodeBudgetExhausted, Op: "inspect physical state", Resource: root,
				Message: "physical state size exceeds supported capacity",
			}
		}
		total += size
		return nil
	})
	if err != nil {
		return 0, err
	}
	return total, nil
}

func (limiter *eventRateLimiter) reserve(limit uint32) bool {
	now := time.Now()
	limiter.Lock()
	defer limiter.Unlock()
	if limiter.window.IsZero() || now.Sub(limiter.window) >= time.Second {
		limiter.window = now
		limiter.count = 0
	}
	if limiter.count >= limit {
		return false
	}
	limiter.count++
	return true
}

func (store *Store) EventsAfter(ctx context.Context, cursor domain.EventCursor, limit uint32) ([]domain.EventEnvelope, error) {
	if limit == 0 {
		return nil, &domain.Error{Code: domain.ErrorCodeInvalidArgument, Resource: "events", Message: "limit is zero"}
	}
	if limit > 1000 {
		return nil, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "events", Message: "limit exceeds 1000",
		}
	}
	rows, err := store.db.QueryContext(
		ctx,
		`SELECT cursor, schema_version, occurred_at, aggregate_kind, aggregate_id, event_type, payload, metadata
         FROM events WHERE cursor > ? ORDER BY cursor LIMIT ?`,
		cursor,
		limit,
	)
	if err != nil {
		return nil, wrap("read events", store.path, err)
	}
	defer rows.Close()
	events := make([]domain.EventEnvelope, 0)
	var responseBytes uint64
	for rows.Next() {
		var event domain.EventEnvelope
		var occurredAt string
		var payload []byte
		var metadata []byte
		if err := rows.Scan(
			&event.Cursor,
			&event.SchemaVersion,
			&occurredAt,
			&event.Aggregate.Kind,
			&event.Aggregate.ID,
			&event.Type,
			&payload,
			&metadata,
		); err != nil {
			return nil, wrap("scan event", store.path, err)
		}
		parsedTime, err := time.Parse(time.RFC3339Nano, occurredAt)
		if err != nil {
			return nil, wrap("parse event time", store.path, err)
		}
		event.OccurredAt = parsedTime
		event.Payload = json.RawMessage(payload)
		responseBytes += uint64(len(payload) + len(metadata))
		if responseBytes > store.budgets.MaxEventBytes {
			return nil, &domain.Error{
				Code: domain.ErrorCodeBudgetExhausted, Op: "read events", Resource: store.path,
				Message: "event response byte limit exceeded",
			}
		}
		if err := json.Unmarshal(metadata, &event.Metadata); err != nil {
			return nil, wrap("decode event metadata", store.path, err)
		}
		if err := event.Validate(); err != nil {
			return nil, err
		}
		events = append(events, event)
	}
	if err := rows.Err(); err != nil {
		return nil, wrap("iterate events", store.path, err)
	}
	return events, nil
}

func wrap(operation string, resource string, err error) error {
	return &domain.Error{Code: domain.ErrorCodeInternal, Op: operation, Resource: resource, Message: err.Error(), Err: err}
}
