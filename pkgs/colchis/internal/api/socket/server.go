package socket

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"mime"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"syscall"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"golang.org/x/sys/unix"
)

const (
	maxCommandBytes    = 1 << 20
	defaultEventLimit  = 100
	maxEventLimit      = 1000
	maxSocketPathBytes = 103
	PrincipalRoleOwner = "owner"
)

type Principal struct {
	UID  uint32 `json:"uid"`
	Role string `json:"role"`
}

func (principal Principal) Identifier() string {
	return fmt.Sprintf("%s:uid:%d", principal.Role, principal.UID)
}

type CommandRequest = domain.CommandRequest

type CommandHandler interface {
	HandleCommand(context.Context, Principal, CommandRequest) (domain.CommandRecord, error)
}

type QueryRequest struct {
	Kind    string          `json:"kind"`
	Payload json.RawMessage `json:"payload"`
}

func (request QueryRequest) Validate() error {
	if request.Kind == "" {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "query kind", Message: "kind is empty",
		}
	}
	if len(request.Payload) == 0 || !json.Valid(request.Payload) {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "query payload", Message: "payload is invalid",
		}
	}
	return nil
}

type QueryHandler interface {
	HandleQuery(context.Context, Principal, QueryRequest) (json.RawMessage, error)
}

type InterruptedCommandRecoverer interface {
	RecoverInterruptedCommands(context.Context) error
}

type CommandHandlerFunc func(context.Context, Principal, CommandRequest) (domain.CommandRecord, error)

func (handler CommandHandlerFunc) HandleCommand(
	ctx context.Context,
	principal Principal,
	request CommandRequest,
) (domain.CommandRecord, error) {
	return handler(ctx, principal, request)
}

type EventReader interface {
	EventsAfter(context.Context, domain.EventCursor, uint32) ([]domain.EventEnvelope, error)
}

type Server struct {
	path            string
	listener        net.Listener
	lock            *os.File
	httpServer      *http.Server
	commands        CommandHandler
	queries         QueryHandler
	events          EventReader
	requestMu       sync.Mutex
	activeRequests  uint64
	closing         bool
	requestsDrained chan struct{}
	ownershipMu     sync.Mutex
}

type Ownership struct {
	path string
	lock *os.File
}

type authenticatedConnection struct {
	net.Conn
	principal Principal
}

type authenticatedListener struct {
	net.Listener
	ownerUID uint32
}

type principalContextKey struct{}

type commandResponse struct {
	Command domain.CommandRecord `json:"command"`
}

type queryResponse struct {
	Result json.RawMessage `json:"result"`
}

type errorResponse struct {
	Error *domain.Error `json:"error"`
}

func Open(path string, commands CommandHandler, events EventReader) (*Server, error) {
	ownership, err := AcquireOwnership(path)
	if err != nil {
		return nil, err
	}
	server, err := OpenOwned(path, ownership, commands, events)
	if err != nil {
		ownership.Close()
		return nil, err
	}
	return server, nil
}

func AcquireOwnership(path string) (*Ownership, error) {
	if path == "" {
		return nil, &domain.Error{Code: domain.ErrorCodeInvalidArgument, Resource: "socket", Message: "path is empty"}
	}
	if err := validateSocketDirectory(filepath.Dir(path)); err != nil {
		return nil, err
	}
	if len(path) > maxSocketPathBytes {
		return nil, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: path,
			Message: "Unix socket path exceeds the portable byte limit",
		}
	}
	lock, err := acquireSocketLock(path + ".lock")
	if err != nil {
		return nil, err
	}
	return &Ownership{path: path, lock: lock}, nil
}

func (ownership *Ownership) Close() error {
	if ownership == nil || ownership.lock == nil {
		return nil
	}
	err := ownership.lock.Close()
	ownership.lock = nil
	return err
}

func OpenOwned(path string, ownership *Ownership, commands CommandHandler, events EventReader) (*Server, error) {
	if commands == nil {
		return nil, &domain.Error{Code: domain.ErrorCodeInvalidArgument, Resource: "command handler", Message: "handler is nil"}
	}
	if events == nil {
		return nil, &domain.Error{Code: domain.ErrorCodeInvalidArgument, Resource: "event reader", Message: "reader is nil"}
	}

	if ownership == nil || ownership.lock == nil || ownership.path != path {
		return nil, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "socket ownership", Message: "ownership does not match socket",
		}
	}
	listener, err := listenOwned(path)
	if err != nil {
		return nil, err
	}
	lock := ownership.lock
	ownership.lock = nil
	if recoverer, ok := commands.(InterruptedCommandRecoverer); ok {
		if err := recoverer.RecoverInterruptedCommands(context.Background()); err != nil {
			listener.Close()
			lock.Close()
			return nil, err
		}
	}
	authenticated := &authenticatedListener{Listener: listener, ownerUID: uint32(os.Geteuid())}
	queries, _ := commands.(QueryHandler)
	server := &Server{
		path:            path,
		listener:        authenticated,
		lock:            lock,
		commands:        commands,
		queries:         queries,
		events:          events,
		requestsDrained: make(chan struct{}),
	}
	mux := http.NewServeMux()
	mux.Handle("/v1/commands", server.trackRequests(http.HandlerFunc(server.handleCommands)))
	mux.Handle("/v1/queries", server.trackRequests(http.HandlerFunc(server.handleQueries)))
	mux.Handle("/v1/events", server.trackRequests(http.HandlerFunc(server.handleEvents)))
	server.httpServer = &http.Server{
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		IdleTimeout:       30 * time.Second,
		MaxHeaderBytes:    32 << 10,
		ConnContext: func(ctx context.Context, connection net.Conn) context.Context {
			authenticatedConnection, ok := connection.(*authenticatedConnection)
			if !ok {
				return ctx
			}
			return context.WithValue(ctx, principalContextKey{}, authenticatedConnection.principal)
		},
	}
	return server, nil
}

func (server *Server) Serve() error {
	err := server.httpServer.Serve(server.listener)
	if errors.Is(err, http.ErrServerClosed) {
		return nil
	}
	return err
}

func (server *Server) Close(ctx context.Context) error {
	drained := server.beginClosing()
	shutdownErr := server.httpServer.Shutdown(ctx)
	var forceErr error
	if shutdownErr != nil {
		forceErr = server.httpServer.Close()
	}
	select {
	case <-drained:
		return errors.Join(shutdownErr, forceErr, server.releaseOwnership())
	default:
		go func() {
			<-drained
			_ = server.releaseOwnership()
		}()
		return errors.Join(shutdownErr, forceErr)
	}
}

func (server *Server) trackRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if !server.beginRequest() {
			writeError(writer, http.StatusServiceUnavailable, &domain.Error{
				Code: domain.ErrorCodeConflict, Resource: "broker", Message: "broker is shutting down",
			})
			return
		}
		defer server.endRequest()
		next.ServeHTTP(writer, request)
	})
}

func (server *Server) beginRequest() bool {
	server.requestMu.Lock()
	defer server.requestMu.Unlock()
	if server.closing {
		return false
	}
	server.activeRequests++
	return true
}

func (server *Server) endRequest() {
	server.requestMu.Lock()
	defer server.requestMu.Unlock()
	server.activeRequests--
	if server.closing && server.activeRequests == 0 {
		close(server.requestsDrained)
	}
}

func (server *Server) beginClosing() <-chan struct{} {
	server.requestMu.Lock()
	defer server.requestMu.Unlock()
	if !server.closing {
		server.closing = true
		if server.activeRequests == 0 {
			close(server.requestsDrained)
		}
	}
	return server.requestsDrained
}

func (server *Server) releaseOwnership() error {
	server.ownershipMu.Lock()
	defer server.ownershipMu.Unlock()
	if server.lock == nil {
		return nil
	}
	err := server.lock.Close()
	server.lock = nil
	return err
}

func (server *Server) SocketPath() string {
	return server.path
}

func (listener *authenticatedListener) Accept() (net.Conn, error) {
	for {
		connection, err := listener.Listener.Accept()
		if err != nil {
			return nil, err
		}
		unixConnection, ok := connection.(*net.UnixConn)
		if !ok {
			connection.Close()
			return nil, &domain.Error{
				Code:     domain.ErrorCodeUnauthorized,
				Resource: "socket peer",
				Message:  "connection is not a Unix socket",
			}
		}
		uid, err := peerUID(unixConnection)
		if err != nil {
			connection.Close()
			return nil, &domain.Error{
				Code:     domain.ErrorCodeUnauthorized,
				Resource: "socket peer",
				Message:  "peer credentials are unavailable",
				Err:      err,
			}
		}
		if uid != listener.ownerUID {
			connection.Close()
			continue
		}
		return &authenticatedConnection{
			Conn:      connection,
			principal: Principal{UID: uid, Role: PrincipalRoleOwner},
		}, nil
	}
}

func validateSocketDirectory(parent string) error {
	if err := validateCreatableSocketAncestors(parent); err != nil {
		return err
	}
	if err := os.MkdirAll(parent, 0o700); err != nil {
		return socketError("create socket directory", parent, err)
	}
	if err := validateSocketAncestors(parent); err != nil {
		return err
	}
	info, err := os.Stat(parent)
	if err != nil {
		return socketError("inspect socket directory", parent, err)
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok || !info.IsDir() || info.Mode().Perm()&0o077 != 0 || stat.Uid != uint32(os.Geteuid()) {
		return &domain.Error{
			Code:     domain.ErrorCodeUnauthorized,
			Resource: parent,
			Message:  "socket directory is accessible by another account",
		}
	}
	return nil
}

func validateCreatableSocketAncestors(path string) error {
	absolute, err := filepath.Abs(path)
	if err != nil {
		return socketError("resolve socket directory", path, err)
	}
	current := absolute
	for {
		if _, err := os.Lstat(current); err == nil {
			return validateSocketAncestors(current)
		} else if !errors.Is(err, os.ErrNotExist) {
			return socketError("inspect socket directory ancestor", current, err)
		}
		parent := filepath.Dir(current)
		if parent == current {
			return validateSocketAncestors(current)
		}
		current = parent
	}
}

func validateSocketAncestors(path string) error {
	absolute, err := filepath.Abs(path)
	if err != nil {
		return socketError("resolve socket directory", path, err)
	}
	if err := validateSocketAncestorChain(absolute, true); err != nil {
		return err
	}
	resolved, err := filepath.EvalSymlinks(absolute)
	if err != nil {
		return socketError("resolve socket directory ancestors", path, err)
	}
	return validateSocketAncestorChain(resolved, false)
}

func validateSocketAncestorChain(path string, allowRootSymlinks bool) error {
	for current := path; ; current = filepath.Dir(current) {
		info, err := os.Lstat(current)
		if err != nil {
			return socketError("inspect socket directory ancestor", current, err)
		}
		stat, ok := info.Sys().(*syscall.Stat_t)
		if info.Mode()&os.ModeSymlink != 0 {
			if !allowRootSymlinks || !ok || stat.Uid != 0 {
				return &domain.Error{
					Code: domain.ErrorCodeConflict, Resource: current,
					Message: "socket directory ancestor is an untrusted symbolic link",
				}
			}
		} else if !ok || (stat.Uid != 0 && stat.Uid != uint32(os.Geteuid())) {
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Resource: current,
				Message: "socket directory ancestor has an untrusted owner",
			}
		} else if !info.IsDir() || (info.Mode().Perm()&0o022 != 0 && info.Mode()&os.ModeSticky == 0) {
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Resource: current,
				Message: "socket directory ancestor permits replacement",
			}
		}
		parent := filepath.Dir(current)
		if parent == current {
			return nil
		}
	}
}

func listenOwned(path string) (net.Listener, error) {
	if err := removeStaleSocket(path); err != nil {
		return nil, err
	}
	listener, err := net.ListenUnix("unix", &net.UnixAddr{Name: path, Net: "unix"})
	if err != nil {
		return nil, socketError("listen", path, err)
	}
	listener.SetUnlinkOnClose(true)
	if err := os.Chmod(path, 0o600); err != nil {
		listener.Close()
		return nil, socketError("restrict socket", path, err)
	}
	return listener, nil
}

func acquireSocketLock(path string) (*os.File, error) {
	descriptor, err := unix.Open(path, unix.O_CREAT|unix.O_RDWR|unix.O_CLOEXEC|unix.O_NOFOLLOW, 0o600)
	if err != nil {
		return nil, socketError("open lock", path, err)
	}
	lock := os.NewFile(uintptr(descriptor), path)
	if err := unix.Flock(descriptor, unix.LOCK_EX|unix.LOCK_NB); err != nil {
		lock.Close()
		return nil, &domain.Error{
			Code: domain.ErrorCodeConflict, Op: "listen", Resource: path, Message: "socket owner is already active", Err: err,
		}
	}
	return lock, nil
}

func removeStaleSocket(path string) error {
	info, err := os.Lstat(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	if err != nil {
		return socketError("inspect", path, err)
	}
	if info.Mode()&os.ModeSocket == 0 {
		return &domain.Error{
			Code:     domain.ErrorCodeConflict,
			Resource: path,
			Message:  "socket path exists and is not a socket",
		}
	}
	connection, dialErr := net.DialTimeout("unix", path, 100*time.Millisecond)
	if dialErr == nil {
		connection.Close()
		return &domain.Error{Code: domain.ErrorCodeConflict, Resource: path, Message: "socket is already active"}
	}
	if errors.Is(dialErr, os.ErrNotExist) {
		return nil
	}
	if !errors.Is(dialErr, syscall.ECONNREFUSED) {
		return &domain.Error{Code: domain.ErrorCodeConflict, Resource: path, Message: "socket liveness is indeterminate"}
	}
	current, err := os.Lstat(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	if err != nil {
		return socketError("inspect stale socket", path, err)
	}
	// Compare the inode again so concurrent startup cannot make this process unlink a new listener.
	if !os.SameFile(info, current) {
		return &domain.Error{Code: domain.ErrorCodeConflict, Resource: path, Message: "socket changed during liveness check"}
	}
	if err := os.Remove(path); err != nil {
		return socketError("remove stale socket", path, err)
	}
	return nil
}

func (server *Server) handleCommands(writer http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodPost {
		writer.Header().Set("Allow", http.MethodPost)
		writeError(writer, http.StatusMethodNotAllowed, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "command endpoint", Message: "method is not allowed",
		})
		return
	}
	mediaType, _, err := mime.ParseMediaType(request.Header.Get("Content-Type"))
	if err != nil || mediaType != "application/json" {
		writeError(writer, http.StatusUnsupportedMediaType, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "command endpoint", Message: "content type must be application/json",
		})
		return
	}
	request.Body = http.MaxBytesReader(writer, request.Body, maxCommandBytes)
	decoder := json.NewDecoder(request.Body)
	decoder.DisallowUnknownFields()
	var command CommandRequest
	if err := decoder.Decode(&command); err != nil {
		writeError(writer, http.StatusBadRequest, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "command", Message: "request body is invalid",
		})
		return
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		writeError(writer, http.StatusBadRequest, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "command", Message: "request body contains multiple values",
		})
		return
	}
	if err := command.Validate(); err != nil {
		writeDomainError(writer, err)
		return
	}
	principal, ok := request.Context().Value(principalContextKey{}).(Principal)
	if !ok {
		writeError(writer, http.StatusUnauthorized, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Resource: "socket peer", Message: "authenticated principal is unavailable",
		})
		return
	}
	record, err := server.commands.HandleCommand(request.Context(), principal, command)
	if err != nil {
		writeDomainError(writer, err)
		return
	}
	if record.Principal != principal.Identifier() {
		writeError(writer, http.StatusInternalServerError, &domain.Error{
			Code: domain.ErrorCodeInternal, Resource: "command", Message: "handler returned a mismatched principal",
		})
		return
	}
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(http.StatusAccepted)
	encoder := json.NewEncoder(writer)
	encoder.SetEscapeHTML(false)
	_ = encoder.Encode(commandResponse{Command: record})
}

func (server *Server) handleQueries(writer http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodPost {
		writer.Header().Set("Allow", http.MethodPost)
		writeError(writer, http.StatusMethodNotAllowed, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "query endpoint", Message: "method is not allowed",
		})
		return
	}
	if server.queries == nil {
		writeError(writer, http.StatusNotImplemented, &domain.Error{
			Code: domain.ErrorCodeInternal, Resource: "query endpoint", Message: "query handler is unavailable",
		})
		return
	}
	mediaType, _, err := mime.ParseMediaType(request.Header.Get("Content-Type"))
	if err != nil || mediaType != "application/json" {
		writeError(writer, http.StatusUnsupportedMediaType, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "query endpoint", Message: "content type must be application/json",
		})
		return
	}
	request.Body = http.MaxBytesReader(writer, request.Body, maxCommandBytes)
	decoder := json.NewDecoder(request.Body)
	decoder.DisallowUnknownFields()
	var query QueryRequest
	if err := decoder.Decode(&query); err != nil {
		writeError(writer, http.StatusBadRequest, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "query", Message: "request body is invalid",
		})
		return
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		writeError(writer, http.StatusBadRequest, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "query", Message: "request body contains multiple values",
		})
		return
	}
	if err := query.Validate(); err != nil {
		writeDomainError(writer, err)
		return
	}
	principal, ok := request.Context().Value(principalContextKey{}).(Principal)
	if !ok {
		writeError(writer, http.StatusUnauthorized, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Resource: "socket peer", Message: "authenticated principal is unavailable",
		})
		return
	}
	result, err := server.queries.HandleQuery(request.Context(), principal, query)
	if err != nil {
		writeDomainError(writer, err)
		return
	}
	if result == nil {
		result = json.RawMessage(`null`)
	}
	writer.Header().Set("Content-Type", "application/json")
	writer.Header().Set("Cache-Control", "no-store")
	writer.WriteHeader(http.StatusOK)
	encoder := json.NewEncoder(writer)
	encoder.SetEscapeHTML(false)
	_ = encoder.Encode(queryResponse{Result: result})
}

func (server *Server) handleEvents(writer http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet {
		writer.Header().Set("Allow", http.MethodGet)
		writeError(writer, http.StatusMethodNotAllowed, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "event endpoint", Message: "method is not allowed",
		})
		return
	}
	if _, ok := request.Context().Value(principalContextKey{}).(Principal); !ok {
		writeError(writer, http.StatusUnauthorized, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Resource: "socket peer", Message: "authenticated principal is unavailable",
		})
		return
	}
	cursor, limit, err := parseEventQuery(request)
	if err != nil {
		writeDomainError(writer, err)
		return
	}
	events, err := server.events.EventsAfter(request.Context(), cursor, limit)
	if err != nil {
		writeDomainError(writer, err)
		return
	}
	previousCursor := cursor
	for _, event := range events {
		if err := event.Validate(); err != nil || event.Cursor <= previousCursor {
			writeError(writer, http.StatusInternalServerError, &domain.Error{
				Code: domain.ErrorCodeInternal, Resource: "events", Message: "reader returned invalid event order",
			})
			return
		}
		previousCursor = event.Cursor
	}
	nextCursor := cursor
	if len(events) > 0 {
		nextCursor = events[len(events)-1].Cursor
	}
	writer.Header().Set("Content-Type", "application/x-ndjson")
	writer.Header().Set("Cache-Control", "no-store")
	writer.Header().Set("X-Colchis-Next-Cursor", strconv.FormatUint(uint64(nextCursor), 10))
	writer.WriteHeader(http.StatusOK)
	encoder := json.NewEncoder(writer)
	encoder.SetEscapeHTML(false)
	for _, event := range events {
		if err := encoder.Encode(event); err != nil {
			return
		}
	}
}

func parseEventQuery(request *http.Request) (domain.EventCursor, uint32, error) {
	values := request.URL.Query()
	invalid := len(values["after"]) > 1 || len(values["limit"]) > 1
	for key := range values {
		if key != "after" && key != "limit" {
			invalid = true
		}
	}
	if invalid {
		return 0, 0, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "event query", Message: "query parameters are invalid",
		}
	}
	var cursor uint64
	var err error
	if value := values.Get("after"); value != "" {
		cursor, err = strconv.ParseUint(value, 10, 64)
		if err != nil || cursor > math.MaxInt64 {
			return 0, 0, &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Resource: "event query", Message: "after is invalid",
			}
		}
	}
	limit := uint64(defaultEventLimit)
	if value := values.Get("limit"); value != "" {
		limit, err = strconv.ParseUint(value, 10, 32)
		if err != nil || limit == 0 || limit > maxEventLimit {
			return 0, 0, &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Resource: "event query", Message: "limit is invalid",
			}
		}
	}
	return domain.EventCursor(cursor), uint32(limit), nil
}

func writeDomainError(writer http.ResponseWriter, err error) {
	var domainError *domain.Error
	if !errors.As(err, &domainError) {
		writeError(writer, http.StatusInternalServerError, &domain.Error{
			Code: domain.ErrorCodeInternal, Resource: "request", Message: "request failed",
		})
		return
	}
	writeError(writer, statusForError(domainError.Code), domainError)
}

func writeError(writer http.ResponseWriter, status int, err *domain.Error) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(status)
	encoder := json.NewEncoder(writer)
	encoder.SetEscapeHTML(false)
	_ = encoder.Encode(errorResponse{Error: err})
}

func statusForError(code domain.ErrorCode) int {
	switch code {
	case domain.ErrorCodeInvalidArgument:
		return http.StatusBadRequest
	case domain.ErrorCodeNotFound:
		return http.StatusNotFound
	case domain.ErrorCodeConflict:
		return http.StatusConflict
	case domain.ErrorCodeUnsupportedVersion:
		return http.StatusUnprocessableEntity
	case domain.ErrorCodeBudgetExhausted:
		return http.StatusTooManyRequests
	case domain.ErrorCodeUnauthorized:
		return http.StatusUnauthorized
	case domain.ErrorCodeIndeterminate:
		return http.StatusConflict
	default:
		return http.StatusInternalServerError
	}
}

func socketError(operation string, path string, err error) error {
	return &domain.Error{
		Code: domain.ErrorCodeInternal, Op: operation, Resource: path, Message: err.Error(), Err: err,
	}
}
