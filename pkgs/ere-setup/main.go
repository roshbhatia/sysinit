package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

type connection struct {
	SSHHost           string   `json:"sshHost"`
	Endpoint          string   `json:"endpoint"`
	Namespace         string   `json:"namespace"`
	CredentialCommand []string `json:"credentialCommand"`
}

type kubeconfig struct {
	APIVersion string `json:"apiVersion"`
	Kind       string `json:"kind"`
	Clusters   []struct {
		Name    string         `json:"name"`
		Cluster map[string]any `json:"cluster"`
	} `json:"clusters"`
	Users []struct {
		Name string         `json:"name"`
		User map[string]any `json:"user"`
	} `json:"users"`
	Contexts       []map[string]any `json:"contexts"`
	CurrentContext string           `json:"current-context"`
}

func configure(raw []byte, name string, c connection) ([]byte, error) {
	var k kubeconfig
	if err := json.Unmarshal(raw, &k); err != nil {
		return nil, err
	}
	if len(k.Clusters) != 1 || len(k.Users) != 1 {
		return nil, errors.New("expected one cluster and one user")
	}
	server, ok := k.Clusters[0].Cluster["server"].(string)
	if !ok {
		return nil, errors.New("missing cluster server")
	}
	u, err := url.Parse(server)
	if err != nil || u.Hostname() == "" {
		return nil, errors.New("invalid cluster server")
	}
	endpoint, err := url.Parse(c.Endpoint)
	if err != nil || endpoint.Scheme != "https" || endpoint.Hostname() == "" {
		return nil, errors.New("endpoint must be an HTTPS URL")
	}
	k.Clusters[0].Name = name
	k.Clusters[0].Cluster["tls-server-name"] = u.Hostname()
	k.Clusters[0].Cluster["server"] = c.Endpoint
	k.Contexts = []map[string]any{{
		"name": name,
		"context": map[string]string{
			"cluster":   name,
			"user":      k.Users[0].Name,
			"namespace": c.Namespace,
		},
	}}
	k.CurrentContext = name
	return json.Marshal(k)
}

func run() error {
	config := flag.String("config", "", "connection JSON file")
	flag.Parse()
	if flag.NArg() != 1 {
		return errors.New("usage: ere-setup --config FILE CONNECTION")
	}
	name := flag.Arg(0)
	if filepath.Base(name) != name || name == "." || name == ".." {
		return errors.New("invalid connection name")
	}
	raw, err := os.ReadFile(*config)
	if err != nil {
		return err
	}
	var connections map[string]connection
	if err := json.Unmarshal(raw, &connections); err != nil {
		return err
	}
	c, ok := connections[name]
	if !ok {
		return fmt.Errorf("unknown connection %q", name)
	}
	if c.SSHHost == "" || strings.HasPrefix(c.SSHHost, "-") || len(c.CredentialCommand) == 0 {
		return errors.New("invalid SSH connection")
	}
	quoted := make([]string, len(c.CredentialCommand))
	for i, v := range c.CredentialCommand {
		quoted[i] = "'" + strings.ReplaceAll(v, "'", "'\"'\"'") + "'"
	}
	cmd := exec.Command("ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", c.SSHHost, strings.Join(quoted, " "))
	cmd.Stderr = os.Stderr
	credentials, err := cmd.Output()
	if err != nil {
		return err
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return err
	}
	directory := filepath.Join(home, ".kube")
	if err := os.MkdirAll(directory, 0700); err != nil {
		return err
	}
	f, err := os.CreateTemp(directory, ".ere-*")
	if err != nil {
		return err
	}
	defer func() {
		if err := os.Remove(f.Name()); err != nil && !os.IsNotExist(err) {
			fmt.Fprintln(os.Stderr, err)
		}
	}()
	if _, err = f.Write(credentials); err != nil {
		_ = f.Close()
		return err
	}
	if err = f.Close(); err != nil {
		return err
	}
	cmd = exec.Command("kubectl", "--kubeconfig", f.Name(), "config", "view", "--raw", "--minify", "-o", "json")
	cmd.Stderr = os.Stderr
	normalized, err := cmd.Output()
	if err != nil {
		return err
	}
	configured, err := configure(normalized, name, c)
	if err != nil {
		return err
	}
	if err := os.WriteFile(f.Name(), configured, 0600); err != nil {
		return err
	}
	cmd = exec.Command("kubectl", "--request-timeout=15s", "--kubeconfig", f.Name(), "get", "namespace", c.Namespace)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return err
	}
	destination := filepath.Join(directory, "ere-"+name+".yaml")
	if err := os.Rename(f.Name(), destination); err != nil {
		return err
	}
	key := filepath.Join(home, ".ssh", "ere")
	if err := os.MkdirAll(filepath.Dir(key), 0700); err != nil {
		return err
	}
	if _, err := os.Stat(key); os.IsNotExist(err) {
		cmd = exec.Command("ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", key)
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return err
		}
	} else if err != nil {
		return err
	}
	fmt.Println("Prepared", destination)
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "ere-setup:", err)
		os.Exit(1)
	}
}
