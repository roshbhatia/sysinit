//go:build darwin

package plugin

import (
	"errors"
	"sync"

	"golang.org/x/sys/unix"
)

type processExitWatcher struct {
	descriptor int
	closeOnce  sync.Once
	closeErr   error
}

func newProcessExitWatcher(pid int) (*processExitWatcher, error) {
	descriptor, err := unix.Kqueue()
	if err != nil {
		return nil, err
	}
	change := unix.Kevent_t{}
	unix.SetKevent(&change, pid, unix.EVFILT_PROC, unix.EV_ADD|unix.EV_ONESHOT)
	change.Fflags = unix.NOTE_EXIT
	if _, err := unix.Kevent(descriptor, []unix.Kevent_t{change}, nil, nil); err != nil {
		_ = unix.Close(descriptor)
		return nil, err
	}
	return &processExitWatcher{descriptor: descriptor}, nil
}

func (watcher *processExitWatcher) Wait() error {
	events := make([]unix.Kevent_t, 1)
	for {
		count, err := unix.Kevent(watcher.descriptor, nil, events, nil)
		if errors.Is(err, unix.EINTR) {
			continue
		}
		if err != nil {
			return err
		}
		if count == 1 {
			return nil
		}
	}
}

func (watcher *processExitWatcher) Close() error {
	watcher.closeOnce.Do(func() { watcher.closeErr = unix.Close(watcher.descriptor) })
	return watcher.closeErr
}

func currentProcessIdentity(pid int) (uint64, bool, error) {
	processes, err := unix.SysctlKinfoProcSlice("kern.proc.pid", pid)
	if err != nil {
		return 0, false, err
	}
	if len(processes) != 1 || int(processes[0].Proc.P_pid) != pid {
		return 0, false, nil
	}
	started := processes[0].Proc.P_starttime
	return uint64(started.Sec)*1_000_000 + uint64(started.Usec), true, nil
}

func processGroupMemberIDs(groupID int) ([]int, error) {
	processes, err := unix.SysctlKinfoProcSlice("kern.proc.all")
	if err != nil {
		return nil, err
	}
	members := make([]int, 0)
	for _, process := range processes {
		if int(process.Eproc.Pgid) == groupID && int(process.Proc.P_pid) > 0 {
			members = append(members, int(process.Proc.P_pid))
		}
	}
	return members, nil
}

func descendantProcessIDs(rootPID int) ([]int, error) {
	processes, err := unix.SysctlKinfoProcSlice("kern.proc.all")
	if err != nil {
		return nil, err
	}
	children := make(map[int][]int)
	for _, process := range processes {
		pid := int(process.Proc.P_pid)
		parentPID := int(process.Eproc.Ppid)
		if pid > 0 && parentPID > 0 {
			children[parentPID] = append(children[parentPID], pid)
		}
	}
	return flattenProcessTree(rootPID, children), nil
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
