package pathguard

import (
	"errors"
	"testing"
)

func TestUIDMapContains(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name    string
		mapping string
		uid     uint32
		mapped  bool
		wantErr bool
	}{
		{name: "full map", mapping: "0 0 4294967295\n", uid: 65534, mapped: true},
		{name: "sandbox map", mapping: "0 30001 1\n", uid: 65534, mapped: false},
		{name: "second range", mapping: "0 30001 1\n1000 1000 10\n", uid: 1005, mapped: true},
		{name: "invalid entry", mapping: "0 0\n", uid: 0, wantErr: true},
		{name: "empty map", mapping: "\n", uid: 0, wantErr: true},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			mapped, err := uidMapContains(test.mapping, test.uid)
			if (err != nil) != test.wantErr {
				t.Fatalf("uidMapContains() error = %v, wantErr %v", err, test.wantErr)
			}
			if mapped != test.mapped {
				t.Fatalf("uidMapContains() = %v, want %v", mapped, test.mapped)
			}
		})
	}
}

func TestRootMountsReadOnly(t *testing.T) {
	t.Parallel()

	readOnly := "36 25 0:32 / / ro,relatime - tmpfs tmpfs rw,size=1024k\n"
	if !rootMountsReadOnly(readOnly) {
		t.Fatal("rootMountsReadOnly() rejected a read-only root mount")
	}
	writableMount := "36 25 0:32 / / rw,relatime - tmpfs tmpfs ro,size=1024k\n"
	if rootMountsReadOnly(writableMount) {
		t.Fatal("rootMountsReadOnly() accepted a writable root mount")
	}
	stackedReadOnly := "36 25 0:32 / / rw,relatime - tmpfs tmpfs rw,size=1024k\n" +
		"38 36 0:34 / / ro,relatime - tmpfs tmpfs rw,size=1024k\n"
	if !rootMountsReadOnly(stackedReadOnly) {
		t.Fatal("rootMountsReadOnly() rejected a visible read-only root mount")
	}
	stackedWritable := readOnly + "38 36 0:34 / / rw,relatime - tmpfs tmpfs rw,size=1024k\n"
	if rootMountsReadOnly(stackedWritable) {
		t.Fatal("rootMountsReadOnly() accepted a visible writable root mount")
	}
	ambiguous := readOnly + "38 25 0:34 / / ro,relatime - tmpfs tmpfs rw,size=1024k\n"
	if rootMountsReadOnly(ambiguous) {
		t.Fatal("rootMountsReadOnly() accepted ambiguous visible root mounts")
	}
	malformed := "36 25 0:32 / / ro,relatime shared:1 tmpfs tmpfs rw,size=1024k\n"
	if rootMountsReadOnly(malformed) {
		t.Fatal("rootMountsReadOnly() accepted metadata without a field separator")
	}
	otherMount := "37 25 0:33 / /build rw,relatime - tmpfs tmpfs rw,size=1024k\n"
	if rootMountsReadOnly(otherMount) {
		t.Fatal("rootMountsReadOnly() accepted metadata without a root mount")
	}
	writableNixSandbox := "591 566 8:1 /nix/store/jv6sdfjrlia7nh393dqr9dv4zp8014aa-sysinit-gotools-0.1.0.drv.chroot/root / rw,relatime - ext4 /dev/root rw\n"
	if !rootMountSafeForOverflowOwner(writableNixSandbox) {
		t.Fatal("rootMountSafeForOverflowOwner() rejected a Nix build sandbox")
	}
	if rootMountSafeForOverflowOwner(writableMount) {
		t.Fatal("rootMountSafeForOverflowOwner() accepted a general writable root")
	}
	if !rootMountSafeForOverflowOwner(readOnly) {
		t.Fatal("rootMountSafeForOverflowOwner() rejected a read-only root")
	}
}

func TestNixBuildSandboxRoot(t *testing.T) {
	t.Parallel()

	valid := "/nix/store/jv6sdfjrlia7nh393dqr9dv4zp8014aa-sysinit-gotools-0.1.0.drv.chroot/root"
	if !nixBuildSandboxRoot(valid) {
		t.Fatal("nixBuildSandboxRoot() rejected a Nix daemon chroot")
	}
	for _, invalid := range []string{
		"/tmp/jv6sdfjrlia7nh393dqr9dv4zp8014aa-build.drv.chroot/root",
		"/nix/store/not-a-store-path.drv.chroot/root",
		"/nix/store/jv6sdfjrlia7nh393dqr9dv4zp8014aa-build.drv.chroot/not-root",
	} {
		if nixBuildSandboxRoot(invalid) {
			t.Fatalf("nixBuildSandboxRoot() accepted %q", invalid)
		}
	}
}

func TestOverflowOwnership(t *testing.T) {
	t.Parallel()

	overflow, mapped, err := overflowOwnership(65534, "65534\n", "65534 1000 1\n")
	if err != nil || !overflow || !mapped {
		t.Fatalf("overflowOwnership() = (%v, %v, %v), want (true, true, nil)", overflow, mapped, err)
	}
	overflow, mapped, err = overflowOwnership(65534, "65534\n", "0 30001 1\n")
	if err != nil || !overflow || mapped {
		t.Fatalf("overflowOwnership() = (%v, %v, %v), want (true, false, nil)", overflow, mapped, err)
	}
}

func TestEffectiveOwnerTrusted(t *testing.T) {
	t.Parallel()

	if effectiveOwnerTrusted("linux", false, false, errors.New("proc unavailable")) {
		t.Fatal("effectiveOwnerTrusted() accepted unavailable Linux namespace metadata")
	}
	if !effectiveOwnerTrusted("darwin", false, false, errors.New("proc unavailable")) {
		t.Fatal("effectiveOwnerTrusted() rejected a Darwin owner without procfs")
	}
	if effectiveOwnerTrusted("linux", true, true, nil) {
		t.Fatal("effectiveOwnerTrusted() accepted a mapped overflow owner")
	}
	if !effectiveOwnerTrusted("linux", true, false, nil) {
		t.Fatal("effectiveOwnerTrusted() rejected an unmapped overflow owner")
	}
}
