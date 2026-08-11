// Package provider defines the inbound port: a source of spec changes that the
// rest of specutil consumes as normalized IR. OpenSpec is the only adapter. The
// port survives its siblings because registry decorates the provider with the
// extraction pass, and a decorator needs an interface to sit behind.
package provider

import "github.com/roshbhatia/specutil/internal/ir"

// Provider discovers and loads spec changes from a filesystem layout into the
// normalized IR. Implementations MUST NOT perform network I/O.
type Provider interface {
	// Name identifies the provider (e.g. "openspec").
	Name() string

	// List returns the names of every change the provider can see, sorted.
	List() ([]string, error)

	// Load reads a single change by name into the IR.
	Load(name string) (*ir.Change, error)

	// LoadAll loads every discoverable change.
	LoadAll() ([]*ir.Change, error)
}
