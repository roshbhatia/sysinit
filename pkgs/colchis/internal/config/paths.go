package config

import (
	"os"
	"path/filepath"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

const StateDirectoryEnvironment = "COLCHIS_STATE_DIR"

type Paths struct {
	StateDirectory string `json:"stateDirectory"`
	Database       string `json:"database"`
	Socket         string `json:"socket"`
	Plugins        string `json:"plugins"`
}

func ResolvePaths(override string) (Paths, error) {
	stateDirectory := override
	if stateDirectory == "" {
		stateDirectory = os.Getenv(StateDirectoryEnvironment)
	}
	if stateDirectory == "" {
		if stateHome := os.Getenv("XDG_STATE_HOME"); stateHome != "" {
			stateDirectory = filepath.Join(stateHome, "colchis")
		} else {
			home, err := os.UserHomeDir()
			if err != nil {
				return Paths{}, pathError("resolve home directory", "state directory", err)
			}
			stateDirectory = filepath.Join(home, ".local", "state", "colchis")
		}
	}
	absolute, err := filepath.Abs(stateDirectory)
	if err != nil {
		return Paths{}, pathError("resolve", stateDirectory, err)
	}
	absolute = filepath.Clean(absolute)
	return Paths{
		StateDirectory: absolute,
		Database:       filepath.Join(absolute, "broker.db"),
		Socket:         filepath.Join(absolute, "broker.sock"),
		Plugins:        filepath.Join(absolute, "plugins.json"),
	}, nil
}

func pathError(operation string, resource string, err error) error {
	return &domain.Error{
		Code: domain.ErrorCodeInvalidArgument, Op: operation, Resource: resource, Message: err.Error(), Err: err,
	}
}
