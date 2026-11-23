package terminalprovider

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/roshbhatia/go-utils/provider"
)

const Selection = "SYSINIT_TERMINAL_PROVIDER"

func Open(path string) (provider.Manifest, error) {
	file, err := os.Open(path)
	if err != nil {
		return provider.Manifest{}, err
	}
	defer func() { _ = file.Close() }()
	return provider.Decode(file, filepath.Ext(path))
}

func Invoke(manifest provider.Manifest, id, action string, input, result any) error {
	body, err := json.Marshal(input)
	if err != nil {
		return err
	}
	invocation, err := provider.Invoke(context.Background(), manifest, provider.Request{
		RequestID:  id,
		Capability: "terminal." + action,
		Operation:  action,
		Input:      body,
	}, provider.InvokeOptions{Timeout: 5 * time.Second})
	if err != nil {
		return err
	}
	if invocation.Result.Status != provider.ResultOK {
		return fmt.Errorf("terminal provider %s: %s", manifest.Name, invocation.Result.Message)
	}
	if result != nil && len(invocation.Result.Output) > 0 {
		return json.Unmarshal(invocation.Result.Output, result)
	}
	return nil
}
