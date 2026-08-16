package schema

import (
	"strings"
	"testing"
)

// The completion keeps its own type list, so drift only shows when somebody
// picks a type the parser no longer accepts.
func TestEveryOfferedTypeParses(t *testing.T) {
	for _, one := range offered {
		if _, err := typeOf(one.kind); err != nil {
			t.Errorf("%s is offered but does not parse: %v", one.kind, err)
		}
	}
}

func TestEveryStarterBuilds(t *testing.T) {
	for _, one := range starters {
		if _, err := Build(one.spec); err != nil {
			t.Errorf("%q is offered but does not build: %v", one.spec, err)
		}
	}
}

func TestComplete(t *testing.T) {
	for _, one := range []struct {
		name  string
		typed string
		first string
		paths bool
	}{
		{"nothing typed offers a whole spec", "", "ok:bool, reason:string", false},
		{"after a colon offers the types", "files:", "files:string", false},
		{"a partial type narrows", "files:[]s", "files:[]string", false},
		{"a later field carries the earlier ones", "a:int, b:", "a:int, b:string", false},
		{"a bare name offers nothing", "files", "", false},
		{"an @ hands over to the shell", "@sch", "", true},
	} {
		t.Run(one.name, func(t *testing.T) {
			offer, paths := Complete(one.typed)
			if paths != one.paths {
				t.Fatalf("paths = %v, want %v", paths, one.paths)
			}
			if one.first == "" {
				if len(offer) != 0 {
					t.Fatalf("wanted nothing, got %v", offer)
				}
				return
			}
			if len(offer) == 0 {
				t.Fatal("wanted an offer, got none")
			}
			got, _, _ := strings.Cut(offer[0], "\t")
			if got != one.first {
				t.Fatalf("got %q, want %q", got, one.first)
			}
		})
	}
}

// Cobra splits an offer on a tab, so a value holding one would lose its tail.
func TestNoOfferHoldsTwoTabs(t *testing.T) {
	for _, typed := range []string{"", "files:", "a:int, b:"} {
		offer, _ := Complete(typed)
		for _, one := range offer {
			if strings.Count(one, "\t") != 1 {
				t.Errorf("%q needs exactly one tab", one)
			}
		}
	}
}
