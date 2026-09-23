package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net"
	"net/url"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strconv"
	"syscall"
	"time"
)

type definition struct {
	Name    string            `json:"name"`
	Type    string            `json:"type"`
	Command string            `json:"command"`
	Args    []string          `json:"args"`
	Env     map[string]string `json:"env"`
	URL     string            `json:"url"`
	Headers map[string]string `json:"headers"`
	Gateway bool              `json:"gateway"`
}

type stdioTarget struct {
	Command string            `json:"cmd"`
	Args    []string          `json:"args,omitempty"`
	Env     map[string]string `json:"env,omitempty"`
}

type remoteTarget struct {
	Host string `json:"host"`
}

type headerModifier struct {
	Set map[string]string `json:"set"`
}

type targetPolicies struct {
	Headers headerModifier `json:"requestHeaderModifier"`
}

type target struct {
	Name     string          `json:"name"`
	Stdio    *stdioTarget    `json:"stdio,omitempty"`
	MCP      *remoteTarget   `json:"mcp,omitempty"`
	SSE      *remoteTarget   `json:"sse,omitempty"`
	Policies *targetPolicies `json:"policies,omitempty"`
}

type apiKey struct {
	Key string `json:"key"`
}

type apiKeys struct {
	Mode string   `json:"mode"`
	Keys []apiKey `json:"keys"`
}

type policies struct {
	APIKey apiKeys `json:"apiKey"`
}

type mcpConfig struct {
	Port          int      `json:"port"`
	PrefixMode    string   `json:"prefixMode"`
	FailureMode   string   `json:"failureMode"`
	DNSProtection bool     `json:"dnsRebindingProtection"`
	Policies      policies `json:"policies"`
	Targets       []target `json:"targets"`
}

type runtimeConfig struct {
	Admin     string `json:"adminAddr"`
	Readiness string `json:"readinessAddr"`
	Stats     string `json:"statsAddr"`
}

type gatewayConfig struct {
	Config runtimeConfig `json:"config"`
	MCP    mcpConfig     `json:"mcp"`
}

func makeConfig(server definition, port int, token string) (gatewayConfig, error) {
	t := target{Name: server.Name}
	switch server.Type {
	case "", "local":
		if server.Command == "" {
			return gatewayConfig{}, errors.New("stdio command is empty")
		}
		t.Stdio = &stdioTarget{server.Command, server.Args, server.Env}
	case "http", "sse":
		u, err := url.Parse(server.URL)
		if err != nil || u.Host == "" || (u.Scheme != "http" && u.Scheme != "https") {
			return gatewayConfig{}, errors.New("invalid upstream URL")
		}
		if server.Type == "sse" {
			t.SSE = &remoteTarget{server.URL}
		} else {
			t.MCP = &remoteTarget{server.URL}
		}
		if len(server.Headers) > 0 {
			t.Policies = &targetPolicies{headerModifier{server.Headers}}
		}
	default:
		return gatewayConfig{}, fmt.Errorf("unsupported transport %q", server.Type)
	}
	return gatewayConfig{
		Config: runtimeConfig{"off", "off", "off"},
		MCP:    mcpConfig{port, "conditional", "failClosed", true, policies{apiKeys{"strict", []apiKey{{token}}}}, []target{t}},
	}, nil
}

func stop(cmd *exec.Cmd, done <-chan error) {
	_ = syscall.Kill(-cmd.Process.Pid, syscall.SIGTERM)
	select {
	case <-done:
	case <-time.After(3 * time.Second):
		_ = syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL)
		<-done
	}
}

func start(cmd *exec.Cmd) (<-chan error, error) {
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	if err := cmd.Start(); err != nil {
		return nil, err
	}
	done := make(chan error, 1)
	go func() {
		done <- cmd.Wait()
		close(done)
	}()
	return done, nil
}

func awaitGateway(ctx context.Context, address string, done <-chan error) error {
	timer := time.NewTimer(15 * time.Second)
	defer timer.Stop()
	tick := time.NewTicker(25 * time.Millisecond)
	defer tick.Stop()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-timer.C:
			return errors.New("gateway startup timed out")
		case err := <-done:
			return fmt.Errorf("gateway exited before startup: %v", err)
		case <-tick.C:
			connection, err := net.DialTimeout("tcp", address, 100*time.Millisecond)
			if err == nil {
				return connection.Close()
			}
		}
	}
}

func run(ctx context.Context, server definition, gateway, proxy string, stdin io.Reader, stdout, stderr io.Writer) error {
	env := os.Environ()
	for key, value := range server.Env {
		env = append(env, key+"="+value)
	}
	endpoint := server.URL
	proxyArgs := []string{"--allow-http", "--silent"}
	if server.Gateway {
		u, err := url.Parse(endpoint)
		if err != nil {
			return err
		}
		if u.Scheme != "http" || (u.Hostname() != "127.0.0.1" && u.Hostname() != "localhost" && u.Hostname() != "::1") {
			return errors.New("existing gateway must use a loopback HTTP URL")
		}
	} else {
		listener, err := net.Listen("tcp", "127.0.0.1:0")
		if err != nil {
			return err
		}
		address := listener.Addr().String()
		_, portString, err := net.SplitHostPort(address)
		if err != nil {
			_ = listener.Close()
			return err
		}
		port, err := strconv.Atoi(portString)
		if err != nil {
			_ = listener.Close()
			return err
		}
		if err := listener.Close(); err != nil {
			return err
		}
		secret := make([]byte, 32)
		if _, err := rand.Read(secret); err != nil {
			return err
		}
		token := hex.EncodeToString(secret)
		config, err := makeConfig(server, port, token)
		if err != nil {
			return err
		}
		data, err := json.Marshal(config)
		if err != nil {
			return err
		}
		directory, err := os.MkdirTemp("", "sysinit-mcp-")
		if err != nil {
			return err
		}
		defer func() { _ = os.RemoveAll(directory) }()
		path := filepath.Join(directory, "gateway.json")
		if err := os.WriteFile(path, data, 0600); err != nil {
			return err
		}
		cmd := exec.Command(gateway, "--file", path)
		// Codex exports http/json, which agentgateway rejects at startup.
		cmd.Env = append(env, "OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf")
		cmd.Stdout, cmd.Stderr = stderr, stderr
		done, err := start(cmd)
		if err != nil {
			return err
		}
		defer stop(cmd, done)
		if err := awaitGateway(ctx, address, done); err != nil {
			return err
		}
		endpoint = "http://" + address + "/mcp"
		proxyArgs = append(proxyArgs, "--header", "Authorization: Bearer ${SYSINIT_MCP_TOKEN}")
		env = append(env, "SYSINIT_MCP_TOKEN="+token)
	}
	cmd := exec.Command(proxy, append([]string{endpoint}, proxyArgs...)...)
	cmd.Env = append(env, "NO_PROXY=127.0.0.1,localhost,::1", "no_proxy=127.0.0.1,localhost,::1")
	cmd.Stdin, cmd.Stdout, cmd.Stderr = stdin, stdout, stderr
	done, err := start(cmd)
	if err != nil {
		return err
	}
	defer stop(cmd, done)
	select {
	case err := <-done:
		return err
	case <-ctx.Done():
		return ctx.Err()
	}
}

func main() {
	gateway := flag.String("gateway", "agentgateway", "agentgateway executable")
	proxy := flag.String("proxy", "mcp-remote", "stdio transport adapter executable")
	check := flag.Bool("probe", false, "initialize and check tool discovery without calling tools")
	flag.Parse()
	if flag.NArg() != 1 {
		fmt.Fprintln(os.Stderr, "usage: mcp-gateway [flags] definition.json")
		os.Exit(2)
	}
	data, err := os.ReadFile(flag.Arg(0))
	var server definition
	if err == nil {
		err = json.Unmarshal(data, &server)
	}
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM, syscall.SIGHUP)
	defer cancel()
	if err == nil {
		if *check {
			err = probe(ctx, server, *gateway, *proxy)
		} else {
			err = run(ctx, server, *gateway, *proxy, os.Stdin, os.Stdout, os.Stderr)
		}
	}
	if err != nil && !errors.Is(err, context.Canceled) {
		fmt.Fprintln(os.Stderr, "mcp-gateway:", err)
		os.Exit(1)
	}
}
