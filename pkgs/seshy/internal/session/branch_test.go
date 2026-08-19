package session

import (
	"os/user"
	"strings"
	"testing"
)

func TestRenderBranchNameDefault(t *testing.T) {
	name, err := RenderBranchName("sy/{{.Session}}/{{.Repo}}", "my-feat", "my-api")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if name != "sy/my-feat/my-api" {
		t.Errorf("expected 'sy/my-feat/my-api', got %q", name)
	}
}

func TestRenderBranchNameCustomTemplate(t *testing.T) {
	name, err := RenderBranchName("feature/{{.Repo}}-{{.Session}}", "v2", "core")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if name != "feature/core-v2" {
		t.Errorf("expected 'feature/core-v2', got %q", name)
	}
}

func TestRenderBranchNameUserVariable(t *testing.T) {
	name, err := RenderBranchName("dev/{{.User}}/{{.Repo}}", "sess", "api")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	u, _ := user.Current()
	if !strings.HasPrefix(name, "dev/"+u.Username+"/") {
		t.Errorf("expected user prefix, got %q", name)
	}
}

func TestRenderBranchNameInvalidTemplate(t *testing.T) {
	_, err := RenderBranchName("sy/{{.Bad", "s", "r")
	if err == nil {
		t.Error("expected error for invalid template")
	}
}

func TestRenderBranchNameRendersInvalidName(t *testing.T) {
	_, err := RenderBranchName("sy/{{.Session}} {{.Repo}}", "my feat", "api")
	if err == nil {
		t.Error("expected error for branch name with spaces")
	}
}

func TestValidateBranchNameValid(t *testing.T) {
	for _, name := range []string{"main", "feature/x", "sy/sess/repo", "a-b_c.d"} {
		if err := ValidateBranchName(name); err != nil {
			t.Errorf("expected valid for %q, got error: %v", name, err)
		}
	}
}

func TestValidateBranchNameEmpty(t *testing.T) {
	if err := ValidateBranchName(""); err == nil {
		t.Error("expected error for empty name")
	}
}

func TestValidateBranchNameSpaces(t *testing.T) {
	if err := ValidateBranchName("my branch"); err == nil {
		t.Error("expected error for spaces")
	}
}

func TestValidateBranchNameDoubleDot(t *testing.T) {
	if err := ValidateBranchName("a..b"); err == nil {
		t.Error("expected error for ..")
	}
}

func TestValidateBranchNameSpecialChars(t *testing.T) {
	for _, c := range []string{"~", "^", ":", "\\", "?", "*", "["} {
		if err := ValidateBranchName("a" + c + "b"); err == nil {
			t.Errorf("expected error for char %q", c)
		}
	}
}

func TestValidateBranchNameLockSuffix(t *testing.T) {
	if err := ValidateBranchName("branch.lock"); err == nil {
		t.Error("expected error for .lock suffix")
	}
}
