package main

import (
	"errors"
	"reflect"
	"testing"
)

func TestDevicesAndStableSelection(t *testing.T) {
	for _, platform := range []string{"darwin", "linux"} {
		t.Run(platform, func(t *testing.T) {
			calls := [][]string{}
			fake := func(name string, args ...string) ([]byte, error) {
				calls = append(calls, append([]string{name}, args...))
				switch len(calls) {
				case 1:
					if platform == "darwin" {
						return []byte(`{"id":"2"}`), nil
					}
					return []byte("sink.two\n"), nil
				case 2:
					if platform == "darwin" {
						return []byte("{\"id\":\"1\",\"name\":\"Same \\\"name\\\"\"}\n{\"id\":\"2\",\"name\":\"Same \\\"name\\\"\"}\n"), nil
					}
					return []byte(`[{"name":"sink.one","description":"Same name"},{"name":"sink.two","description":"Same name"}]`), nil
				default:
					return nil, nil
				}
			}
			items, err := devices(platform, fake)
			if err != nil {
				t.Fatal(err)
			}
			if len(items) != 2 || items[0].Current || !items[1].Current {
				t.Fatalf("bad devices: %+v", items)
			}
			if err = set(platform, items[1].ID, items, fake); err != nil {
				t.Fatal(err)
			}
			want := []string{"pactl", "set-default-sink", "sink.two"}
			if platform == "darwin" {
				want = []string{"SwitchAudioSource", "-t", "output", "-i", "2"}
			}
			if !reflect.DeepEqual(calls[2], want) {
				t.Fatalf("set call: %v", calls[2])
			}
			if err = set(platform, "unknown", items, fake); err == nil || len(calls) != 3 {
				t.Fatal("unknown device must not mutate")
			}
		})
	}
}

func TestDiscoveryFailure(t *testing.T) {
	for _, data := range []string{"{", "{\"id\":\"1\"}\n{"} {
		n := 0
		_, err := devices("darwin", func(string, ...string) ([]byte, error) {
			n++
			if n == 1 {
				return []byte(`{"id":"1"}`), nil
			}
			return []byte(data), nil
		})
		if err == nil {
			t.Fatal("malformed discovery accepted")
		}
	}
	_, err := devices("linux", func(string, ...string) ([]byte, error) { return nil, errors.New("offline") })
	if err == nil {
		t.Fatal("failure ignored")
	}
}
