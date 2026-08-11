// Package provider defines the inbound port: a source of spec changes that the
// rest of specutil consumes as normalized IR. OpenSpec is the only adapter that
// ships in v1, but the port keeps the core framework-agnostic.
package provider

import "github.com/roshbhatia/specutil/internal/ir"

// Provider discovers and loads spec changes from some backing store (a
// filesystem layout, in the OpenSpec case) into the normalized IR. Implementations
// MUST NOT perform network I/O.
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
