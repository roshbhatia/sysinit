package provider

import "github.com/roshbhatia/sysinit/pkgs/specutil/internal/ir"

type Provider interface {
	Name() string

	List() ([]string, error)

	Load(name string) (*ir.Change, error)

	LoadAll() ([]*ir.Change, error)
}
