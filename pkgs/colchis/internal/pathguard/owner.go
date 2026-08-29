package pathguard

import (
	"errors"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
)

type rootMountRecord struct {
	parent     uint64
	readOnly   bool
	sourceRoot string
}

func TrustedAncestorOwner(uid uint32, isFilesystemRoot bool) bool {
	if uid == 0 {
		return true
	}
	if uid == uint32(os.Geteuid()) {
		overflow, mapped, err := currentOverflowOwnership(uid)
		return effectiveOwnerTrusted(runtime.GOOS, overflow, mapped, err)
	}
	if !isFilesystemRoot {
		return false
	}
	mountInfo, err := os.ReadFile("/proc/self/mountinfo")
	if err != nil || !rootMountSafeForOverflowOwner(string(mountInfo)) {
		return false
	}
	overflow, mapped, err := currentOverflowOwnership(uid)
	return err == nil && overflow && !mapped
}

func rootMountsReadOnly(mountInfo string) bool {
	root, ok := visibleRootMount(mountInfo)
	return ok && root.readOnly
}

func rootMountSafeForOverflowOwner(mountInfo string) bool {
	root, ok := visibleRootMount(mountInfo)
	return ok && (root.readOnly || nixBuildSandboxRoot(root.sourceRoot))
}

func visibleRootMount(mountInfo string) (rootMountRecord, bool) {
	mounts := make(map[uint64]rootMountRecord)
	rootIDs := make(map[uint64]struct{})
	for _, line := range strings.Split(mountInfo, "\n") {
		fields := strings.Fields(line)
		if len(fields) == 0 {
			continue
		}
		if len(fields) < 10 {
			return rootMountRecord{}, false
		}
		separator := -1
		for index := 6; index < len(fields); index++ {
			if fields[index] == "-" {
				separator = index
				break
			}
		}
		if separator < 0 || separator+3 >= len(fields) {
			return rootMountRecord{}, false
		}
		id, idErr := strconv.ParseUint(fields[0], 10, 64)
		parent, parentErr := strconv.ParseUint(fields[1], 10, 64)
		if idErr != nil || parentErr != nil {
			return rootMountRecord{}, false
		}
		if _, duplicate := mounts[id]; duplicate {
			return rootMountRecord{}, false
		}
		root := fields[4] == string(os.PathSeparator)
		readOnly := false
		if root {
			for _, option := range strings.Split(fields[5], ",") {
				if option == "ro" {
					readOnly = true
					break
				}
			}
			rootIDs[id] = struct{}{}
		}
		mounts[id] = rootMountRecord{parent: parent, readOnly: readOnly, sourceRoot: fields[3]}
	}
	if len(rootIDs) == 0 {
		return rootMountRecord{}, false
	}

	hiddenRoots := make(map[uint64]struct{})
	for id := range rootIDs {
		seen := make(map[uint64]struct{})
		parent := mounts[id].parent
		for {
			if _, cycle := seen[parent]; cycle {
				return rootMountRecord{}, false
			}
			seen[parent] = struct{}{}
			if _, root := rootIDs[parent]; root {
				hiddenRoots[parent] = struct{}{}
			}
			record, found := mounts[parent]
			if !found || record.parent == parent {
				break
			}
			parent = record.parent
		}
	}

	visibleRoots := 0
	visible := rootMountRecord{}
	for id := range rootIDs {
		if _, hidden := hiddenRoots[id]; hidden {
			continue
		}
		visibleRoots++
		visible = mounts[id]
		if visibleRoots > 1 {
			return rootMountRecord{}, false
		}
	}
	return visible, visibleRoots == 1
}

func nixBuildSandboxRoot(root string) bool {
	clean := filepath.Clean(root)
	if filepath.Base(clean) != "root" {
		return false
	}
	chroot := filepath.Dir(clean)
	if filepath.Dir(chroot) != "/nix/store" {
		return false
	}
	name := strings.TrimSuffix(filepath.Base(chroot), ".drv.chroot")
	if name == filepath.Base(chroot) || len(name) < 34 || name[32] != '-' {
		return false
	}
	const nixBase32 = "0123456789abcdfghijklmnpqrsvwxyz"
	for _, character := range name[:32] {
		if !strings.ContainsRune(nixBase32, character) {
			return false
		}
	}
	return true
}

func currentOverflowOwnership(uid uint32) (bool, bool, error) {
	overflowRaw, err := os.ReadFile("/proc/sys/kernel/overflowuid")
	if err != nil {
		return false, false, err
	}
	mapping, err := os.ReadFile("/proc/self/uid_map")
	if err != nil {
		return false, false, err
	}
	return overflowOwnership(uid, string(overflowRaw), string(mapping))
}

func effectiveOwnerTrusted(goos string, overflow bool, mapped bool, metadataErr error) bool {
	if metadataErr != nil {
		return goos != "linux"
	}
	return !overflow || !mapped
}

func overflowOwnership(uid uint32, overflowRaw string, mapping string) (bool, bool, error) {
	overflow, err := strconv.ParseUint(strings.TrimSpace(overflowRaw), 10, 32)
	if err != nil {
		return false, false, err
	}
	if uid != uint32(overflow) {
		return false, false, nil
	}
	mapped, err := uidMapContains(mapping, uid)
	return true, mapped, err
}

func uidMapContains(mapping string, uid uint32) (bool, error) {
	entries := 0
	for _, line := range strings.Split(mapping, "\n") {
		fields := strings.Fields(line)
		if len(fields) == 0 {
			continue
		}
		if len(fields) != 3 {
			return false, errors.New("uid map entry has an invalid field count")
		}
		inside, insideErr := strconv.ParseUint(fields[0], 10, 32)
		_, outsideErr := strconv.ParseUint(fields[1], 10, 32)
		length, lengthErr := strconv.ParseUint(fields[2], 10, 32)
		if insideErr != nil || outsideErr != nil || lengthErr != nil || length == 0 {
			return false, errors.New("uid map entry is invalid")
		}
		entries++
		value := uint64(uid)
		if value >= inside && value < inside+length {
			return true, nil
		}
	}
	if entries == 0 {
		return false, errors.New("uid map is empty")
	}
	return false, nil
}
