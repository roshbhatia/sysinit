package main

import (
	"encoding/json"
	"testing"
)

func TestConfigureArbitraryConnection(t *testing.T) {
	raw := []byte(`{"apiVersion":"v1","kind":"Config","clusters":[{"name":"default","cluster":{"server":"https://127.0.0.1:6443","certificate-authority-data":"cert"}}],"users":[{"name":"admin","user":{"token":"test"}}]}`)
	result, err := configure(raw, "new-host", connection{Endpoint: "https://different-host:7443", Namespace: "private"})
	if err != nil {
		t.Fatal(err)
	}
	var config kubeconfig
	if err := json.Unmarshal(result, &config); err != nil {
		t.Fatal(err)
	}
	if config.CurrentContext != "new-host" || config.Clusters[0].Cluster["server"] != "https://different-host:7443" || config.Clusters[0].Cluster["tls-server-name"] != "127.0.0.1" || config.Clusters[0].Cluster["certificate-authority-data"] != "cert" {
		t.Fatal("connection was not preserved")
	}
	if _, err := configure(raw, "new-host", connection{Endpoint: "http://insecure"}); err == nil {
		t.Fatal("accepted insecure endpoint")
	}
	if _, err := configure([]byte(`{}`), "new-host", connection{}); err == nil {
		t.Fatal("accepted missing cluster")
	}
}
