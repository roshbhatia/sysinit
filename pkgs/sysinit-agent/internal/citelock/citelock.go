// Package citelock implements the `citelock` command: an offline gate over a
package citelock

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/store"
)

const Summary = "offline gate over a change's citations.lock"

const (
	lockfileName = "citations.lock"
	snapDirName  = "citations"
)

const usageText = `Citation capture and the offline gate over citations.lock.

Usage:
  citelock verify [<lockdir>]
  citelock capture <url> --id <id> --quote <text> --class <class> [--doi <doi>] [--lockdir <dir>]
  citelock recheck [<lockdir>]

Claim classes and their freshness windows:
  pricing, availability   30 days
  api                     90 days
  paper                   no expiry
  anything else          180 days
`

// Record is one citation.
type Record struct {
	ID         string `json:"id"`
	Source     string `json:"source"`
	Accessed   string `json:"accessed"`
	ClaimClass string `json:"claim_class"`
	Quote      string `json:"quote"`
	Snapshot   string `json:"snapshot"`
	SHA256     string `json:"sha256"`
	DOI        string `json:"doi,omitempty"`
}

type lockfile struct {
	Records []json.RawMessage `json:"records"`
}

func logf(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "citelock: "+format+"\n", args...)
}

type fail struct{ msg string }

func (e *fail) Error() string { return e.msg }

func die(format string, args ...any) error {
	return &fail{msg: fmt.Sprintf(format, args...)}
}

// Run dispatches the subcommand and returns the process exit code.
func Run(args []string) int {
	cmd := "verify"
	if len(args) > 0 {
		cmd = args[0]
		args = args[1:]
	}
	var err error
	switch cmd {
	case "-h", "--help", "help":
		fmt.Print(usageText)
		return 0
	case "verify":
		err = verify(firstOr(args, "."))
	case "capture":
		if len(args) < 1 {
			err = die("capture requires a URL")
			break
		}
		err = capture(args[0], args[1:])
	case "recheck":
		err = recheck(firstOr(args, "."))
	default:
		err = die("unknown command: %s (verify|capture|recheck)", cmd)
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "citelock: ERROR: %s\n", err)
		return 1
	}
	return 0
}

func firstOr(args []string, fallback string) string {
	if len(args) > 0 && args[0] != "" {
		return args[0]
	}
	return fallback
}

func lockPath(dir string) string { return filepath.Join(dir, lockfileName) }

// freshnessDays is the age a claim of this class may reach before it has to be
func freshnessDays(class string) int {
	switch class {
	case "pricing", "availability":
		return 30
	case "api":
		return 90
	case "paper":
		return 0
	default:
		return 180
	}
}

func sha256File(path string) (string, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:]), nil
}

// anchored reports whether the verbatim quote appears in the snapshot.
func anchored(path, quote string) (bool, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return false, err
	}
	return strings.Contains(string(data), quote), nil
}

func readLock(path string) (*lockfile, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var lock lockfile
	if err := json.Unmarshal(data, &lock); err != nil {
		return nil, err
	}
	return &lock, nil
}

func verify(lockdir string) error {
	lock := lockPath(lockdir)
	if _, err := os.Stat(lock); err != nil {
		logf("no %s in %s; nothing to verify (no-op)", lockfileName, lockdir)
		return nil
	}

	parsed, err := readLock(lock)
	if err != nil {
		return die("could not read %s: %v", lock, err)
	}

	failed := false
	now := time.Now()
	for _, raw := range parsed.Records {
		if !verifyRecord(raw, lockdir, now) {
			failed = true
		}
	}

	if failed {
		return die("offline gate failed for %s", lock)
	}
	logf("offline gate passed: %s", lock)
	return nil
}

func verifyRecord(raw json.RawMessage, lockdir string, now time.Time) bool {
	var rec Record
	if err := json.Unmarshal(raw, &rec); err != nil {
		logf("[?] format: record is not an object")
		return false
	}
	id := rec.ID
	if id == "" {
		id = "null"
	}

	if rec.Source == "" || rec.Quote == "" || rec.Snapshot == "" ||
		rec.SHA256 == "" || rec.Accessed == "" || rec.ClaimClass == "" {
		logf("[%s] format: missing required field (source/quote/snapshot/sha256/accessed/claim_class)", id)
		return false
	}

	snapFile := filepath.Join(lockdir, rec.Snapshot)
	prov := snapFile + ".prov.json"

	if _, err := os.Stat(snapFile); err != nil {
		logf("[%s] snapshot missing: %s", id, snapFile)
		return false
	}
	if _, err := os.Stat(prov); err != nil {
		logf("[%s] no capture provenance sidecar (%s.prov.json); hand-authored snapshots are rejected", id, rec.Snapshot)
		return false
	}

	actual, err := sha256File(snapFile)
	if err != nil {
		logf("[%s] integrity: could not hash %s", id, snapFile)
		return false
	}
	if actual != rec.SHA256 {
		logf("[%s] integrity: snapshot sha256 mismatch (recorded %s, actual %s)", id, rec.SHA256, actual)
		return false
	}
	provSHA := ""
	if data, err := os.ReadFile(prov); err == nil {
		var sidecar struct {
			SHA256 string `json:"sha256"`
		}
		if json.Unmarshal(data, &sidecar) == nil {
			provSHA = sidecar.SHA256
		}
	}
	if provSHA != rec.SHA256 {
		logf("[%s] integrity: provenance sha256 does not match record", id)
		return false
	}

	ok, err := anchored(snapFile, rec.Quote)
	if err != nil || !ok {
		logf("[%s] unanchored: verbatim quote not found in snapshot", id)
		return false
	}

	maxDays := freshnessDays(rec.ClaimClass)
	if maxDays <= 0 {
		return true
	}
	accessed, err := time.ParseInLocation("2006-01-02", rec.Accessed, time.Local)
	if err != nil {
		logf("[%s] freshness: unparseable accessed date '%s'", id, rec.Accessed)
		return false
	}
	ageDays := int(now.Sub(accessed).Seconds()) / 86400
	if ageDays > maxDays {
		logf("[%s] stale: %s claim accessed %dd ago (max %dd)", id, rec.ClaimClass, ageDays, maxDays)
		return false
	}
	return true
}

// assertSafeURL refuses a source the capture path must never fetch.
func assertSafeURL(rawURL string) error {
	if !strings.HasPrefix(rawURL, "https://") {
		return die("refusing non-https source (scheme allowlist): %s", rawURL)
	}
	host := strings.TrimPrefix(rawURL, "https://")
	if i := strings.Index(host, "/"); i >= 0 {
		host = host[:i]
	}
	if i := strings.LastIndex(host, "@"); i >= 0 {
		host = host[i+1:]
	}
	if i := strings.Index(host, ":"); i >= 0 {
		host = host[:i]
	}

	switch {
	case host == "":
		return die("could not parse host from URL: %s", rawURL)
	case host == "localhost" || host == "localhost." || strings.HasSuffix(host, ".localhost"):
		return die("refusing loopback host: %s", host)
	case strings.HasPrefix(host, "["):
		return die("refusing IPv6-literal host: %s", host)
	case host == "metadata.google.internal" || strings.HasSuffix(host, ".internal"):
		return die("refusing internal/metadata host: %s", host)
	case strings.HasPrefix(host, "127.") || strings.HasPrefix(host, "0.") ||
		strings.HasPrefix(host, "169.254.") || strings.HasPrefix(host, "10.") ||
		strings.HasPrefix(host, "192.168."):
		return die("refusing loopback/link-local/RFC-1918 host: %s", host)
	case privateClassB(host):
		return die("refusing RFC-1918 host: %s", host)
	case strings.HasPrefix(host, "0x") || strings.Contains(host, ".0x"):
		return die("refusing hex-IP host: %s", host)
	}
	if strings.IndexFunc(host, func(r rune) bool {
		return (r < '0' || r > '9') && r != '.'
	}) < 0 {
		return die("refusing numeric-IP host (cite a DNS name): %s", host)
	}
	return nil
}

func privateClassB(host string) bool {
	if !strings.HasPrefix(host, "172.") {
		return false
	}
	rest := host[len("172."):]
	dot := strings.Index(rest, ".")
	if dot < 0 {
		return false
	}
	var octet int
	if _, err := fmt.Sscanf(rest[:dot], "%d", &octet); err != nil {
		return false
	}
	return octet >= 16 && octet <= 31
}

func have(tool string) bool {
	_, err := exec.LookPath(tool)
	return err == nil
}

func run(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = nil
	cmd.Stderr = nil
	return cmd.Run()
}

// liveChecks confirms the source is still reachable and, for a DOI, not
func liveChecks(url, doi string) error {
	if os.Getenv("CITELOCK_OFFLINE") == "1" {
		logf("CITELOCK_OFFLINE=1: skipping live checks (advisory)")
		return nil
	}
	switch {
	case have("lychee"):
		if run("lychee", "--no-progress", "--max-retries", "1", "--", url) != nil {
			if have("pplx") && run("pplx", "content", "fetch", url) == nil {
				logf("live: lychee could not confirm %s; pplx fetched it, treating as live", url)
			} else {
				logf("live: neither lychee nor pplx could confirm %s (dead link or transient); treat as fail at capture", url)
				return errors.New("not live")
			}
		}
	case have("pplx"):
		if run("pplx", "content", "fetch", url) != nil {
			logf("live: pplx could not fetch %s (dead link or transient); treat as fail at capture", url)
			return errors.New("not live")
		}
	default:
		logf("live: neither lychee nor pplx on PATH; skipping liveness")
	}

	if doi == "" {
		return nil
	}
	out, err := exec.Command("curl", "-fsS", "--max-time", "20",
		"https://api.crossref.org/works/"+doi).Output()
	if err != nil {
		logf("live: Crossref lookup for %s failed (nonexistent DOI or transient)", doi)
		return errors.New("crossref lookup failed")
	}
	var body struct {
		Message struct {
			UpdateTo []struct {
				Type string `json:"type"`
			} `json:"update-to"`
		} `json:"message"`
	}
	if json.Unmarshal(out, &body) == nil {
		for _, update := range body.Message.UpdateTo {
			if update.Type == "retraction" {
				logf("live: DOI %s is retracted (Crossref update-to)", doi)
				return errors.New("retracted")
			}
		}
	}
	return nil
}

func capture(url string, args []string) error {
	var id, quote, class, doi string
	lockdir := "."
	for i := 0; i < len(args); {
		if i+1 >= len(args) {
			return die("%s needs a value", args[i])
		}
		switch args[i] {
		case "--id":
			id = args[i+1]
		case "--quote":
			quote = args[i+1]
		case "--class":
			class = args[i+1]
		case "--doi":
			doi = args[i+1]
		case "--lockdir":
			lockdir = args[i+1]
		default:
			return die("unknown capture flag: %s", args[i])
		}
		i += 2
	}
	if id == "" || quote == "" || class == "" {
		return die("capture requires --id, --quote, --class")
	}
	if err := assertSafeURL(url); err != nil {
		return err
	}

	snapRel := filepath.Join(snapDirName, id+".snapshot")
	snapFile := filepath.Join(lockdir, snapRel)
	prov := snapFile + ".prov.json"
	if err := os.MkdirAll(filepath.Join(lockdir, snapDirName), 0o755); err != nil {
		return err
	}

	tmp, err := os.CreateTemp("", "citelock.*")
	if err != nil {
		return err
	}
	tmpName := tmp.Name()
	tmp.Close()
	defer os.Remove(tmpName)

	engine := "curl"
	if have("monolith") {
		if run("monolith", "--no-audio", "--no-video", "--no-frames", "--silent",
			"--output", tmpName, "--", url) == nil {
			engine = "monolith"
		}
	}
	if info, err := os.Stat(tmpName); err != nil || info.Size() == 0 {
		engine = "curl"
		if err := run("curl", "-fsS", "--max-redirs", "0", "--max-time", "30",
			"-o", tmpName, "--", url); err != nil {
			return die("capture: fetch failed (or redirected) for %s", url)
		}
	}

	ok, err := anchored(tmpName, quote)
	if err != nil {
		return err
	}
	if !ok {
		return die("capture: quote does not anchor in fetched content for %s. "+
			"If this is a client-rendered page, cite a stable/archived URL or the underlying JSON API.", id)
	}

	data, err := os.ReadFile(tmpName)
	if err != nil {
		return err
	}
	if err := os.WriteFile(snapFile, data, 0o644); err != nil {
		return err
	}
	sum, err := sha256File(snapFile)
	if err != nil {
		return err
	}
	sidecar, err := json.Marshal(struct {
		URL        string `json:"url"`
		HTTPStatus int    `json:"http_status"`
		Engine     string `json:"engine"`
		SHA256     string `json:"sha256"`
	}{URL: url, HTTPStatus: 200, Engine: engine, SHA256: sum})
	if err != nil {
		return err
	}
	if err := os.WriteFile(prov, append(sidecar, '\n'), 0o644); err != nil {
		return err
	}

	if err := liveChecks(url, doi); err != nil {
		return die("capture: live-web check failed for %s", id)
	}

	if err := upsert(lockdir, Record{
		ID:         id,
		Source:     url,
		Accessed:   time.Now().Format("2006-01-02"),
		ClaimClass: class,
		Quote:      quote,
		Snapshot:   snapRel,
		SHA256:     sum,
		DOI:        doi,
	}); err != nil {
		return err
	}
	logf("captured [%s] -> %s (sha %s)", id, snapRel, sum[:12])
	return nil
}

// upsert replaces any record with the same id and appends the new one.
func upsert(lockdir string, rec Record) error {
	path := lockPath(lockdir)
	s := &store.Store{
		Path: path,
		Validate: store.JSONValidator(func(doc struct {
			Records *[]json.RawMessage `json:"records"`
		}) error {
			if doc.Records == nil {
				return errors.New("no records array")
			}
			return nil
		}),
		Initial: func() ([]byte, error) {
			return []byte(`{"records":[]}` + "\n"), nil
		},
	}

	release, err := s.Lock()
	if err != nil {
		return err
	}
	defer release()

	data, err := s.Read()
	if err != nil {
		return err
	}
	var lock lockfile
	if err := json.Unmarshal(data, &lock); err != nil {
		return err
	}

	kept := make([]json.RawMessage, 0, len(lock.Records)+1)
	for _, raw := range lock.Records {
		var cur struct {
			ID string `json:"id"`
		}
		if json.Unmarshal(raw, &cur) == nil && cur.ID == rec.ID {
			continue
		}
		kept = append(kept, raw)
	}
	encoded, err := json.Marshal(rec)
	if err != nil {
		return err
	}
	lock.Records = append(kept, encoded)

	out, err := json.MarshalIndent(lock, "", "  ")
	if err != nil {
		return err
	}
	return s.Publish(append(out, '\n'))
}

func recheck(lockdir string) error {
	lock := lockPath(lockdir)
	if _, err := os.Stat(lock); err != nil {
		logf("no %s in %s; nothing to recheck", lockfileName, lockdir)
		return nil
	}
	parsed, err := readLock(lock)
	if err != nil {
		return die("could not read %s: %v", lock, err)
	}

	failed := false
	for _, raw := range parsed.Records {
		var rec Record
		if err := json.Unmarshal(raw, &rec); err != nil {
			logf("[?] recheck failed: record is not an object")
			failed = true
			continue
		}
		if err := assertSafeURL(rec.Source); err != nil {
			return err
		}
		if err := liveChecks(rec.Source, rec.DOI); err != nil {
			logf("[%s] recheck failed", rec.ID)
			failed = true
		}
	}
	if failed {
		return die("recheck found dead/retracted sources in %s", lock)
	}
	logf("recheck passed: %s", lock)
	return nil
}
