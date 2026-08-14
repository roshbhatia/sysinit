package provider

import "github.com/roshbhatia/specutil/internal/ir"

type Provider interface {
	Name() string

	List() ([]string, error)

	Load(name string) (*ir.Change, error)

	LoadAll() ([]*ir.Change, error)
}
