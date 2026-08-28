//go:build linux

package plugin

import (
	"errors"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"

	"golang.org/x/sys/unix"
)

type processExitWatcher struct {
	descriptor int
	closeOnce  sync.Once
	closeErr   error
}

func newProcessExitWatcher(pid int) (*processExitWatcher, error) {
	descriptor, err := unix.PidfdOpen(pid, 0)
	if err != nil {
		return nil, err
	}
	return &processExitWatcher{descriptor: descriptor}, nil
}

func (watcher *processExitWatcher) Wait() error {
	descriptors := []unix.PollFd{{Fd: int32(watcher.descriptor), Events: unix.POLLIN}}
	for {
		count, err := unix.Poll(descriptors, -1)
		if errors.Is(err, unix.EINTR) {
			continue
		}
		if err != nil {
			return err
		}
		if count == 1 && descriptors[0].Revents&(unix.POLLIN|unix.POLLHUP) != 0 {
			return nil
		}
	}
}

func (watcher *processExitWatcher) Close() error {
	watcher.closeOnce.Do(func() { watcher.closeErr = unix.Close(watcher.descriptor) })
	return watcher.closeErr
}

func descendantProcessIDs(rootPID int) ([]int, error) {
	entries, err := os.ReadDir("/proc")
	if err != nil {
		return nil, err
	}
	children := make(map[int][]int)
	for _, entry := range entries {
		pid, parseErr := strconv.Atoi(entry.Name())
		if parseErr != nil || pid <= 0 {
			continue
		}
		payload, readErr := os.ReadFile(filepath.Join("/proc", entry.Name(), "stat"))
		if readErr != nil {
			if errors.Is(readErr, os.ErrNotExist) {
				continue
			}
			return nil, readErr
		}
		parentPID, parseErr := linuxParentPID(payload)
		if parseErr != nil {
			return nil, parseErr
		}
		if parentPID > 0 {
			children[parentPID] = append(children[parentPID], pid)
		}
	}
	return flattenProcessTree(rootPID, children), nil
}

func currentProcessIdentity(pid int) (uint64, bool, error) {
	payload, err := os.ReadFile(filepath.Join("/proc", strconv.Itoa(pid), "stat"))
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return 0, false, nil
		}
		return 0, false, err
	}
	fields, err := linuxStatFields(payload)
	if err != nil {
		return 0, false, err
	}
	if len(fields) < 20 {
		return 0, false, strconv.ErrSyntax
	}
	identity, err := strconv.ParseUint(fields[19], 10, 64)
	return identity, err == nil, err
}

func processGroupMemberIDs(groupID int) ([]int, error) {
	entries, err := os.ReadDir("/proc")
	if err != nil {
		return nil, err
	}
	members := make([]int, 0)
	for _, entry := range entries {
		pid, parseErr := strconv.Atoi(entry.Name())
		if parseErr != nil || pid <= 0 {
			continue
		}
		payload, readErr := os.ReadFile(filepath.Join("/proc", entry.Name(), "stat"))
		if readErr != nil {
			if errors.Is(readErr, os.ErrNotExist) {
				continue
			}
			return nil, readErr
		}
		fields, parseErr := linuxStatFields(payload)
		if parseErr != nil || len(fields) < 3 {
			return nil, strconv.ErrSyntax
		}
		processGroupID, parseErr := strconv.Atoi(fields[2])
		if parseErr != nil {
			return nil, parseErr
		}
		if processGroupID == groupID {
			members = append(members, pid)
		}
	}
	return members, nil
}

func linuxParentPID(payload []byte) (int, error) {
	fields, err := linuxStatFields(payload)
	if err != nil {
		return 0, err
	}
	if len(fields) < 2 {
		return 0, strconv.ErrSyntax
	}
	return strconv.Atoi(fields[1])
}

func linuxStatFields(payload []byte) ([]string, error) {
	closing := strings.LastIndexByte(string(payload), ')')
	if closing < 0 {
		return nil, strconv.ErrSyntax
	}
	fields := strings.Fields(string(payload[closing+1:]))
	return fields, nil
}

func flattenProcessTree(rootPID int, children map[int][]int) []int {
	descendants := make([]int, 0)
	queue := append([]int(nil), children[rootPID]...)
	for len(queue) > 0 {
		pid := queue[0]
		queue = queue[1:]
		descendants = append(descendants, pid)
		queue = append(queue, children[pid]...)
	}
	return descendants
}
