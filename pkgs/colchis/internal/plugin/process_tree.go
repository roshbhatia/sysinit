package plugin

import (
	"errors"
	"os/exec"
	"sync"
	"syscall"
)

type ownedProcessTree struct {
	rootPID      int
	rootIdentity uint64
}

type ProcessSupervisor struct {
	command *exec.Cmd
	tree    ownedProcessTree
	watcher *processExitWatcher

	waitOnce sync.Once
	waitDone chan struct{}
	waitErr  error
}

func ProcessIdentity(pid int) (uint64, bool, error) {
	return currentProcessIdentity(pid)
}

func SuperviseStartedCommand(command *exec.Cmd) (*ProcessSupervisor, error) {
	if command == nil || command.Process == nil {
		return nil, syscall.ESRCH
	}
	tree, err := captureOwnedProcessTree(command.Process.Pid)
	if err != nil {
		return nil, err
	}
	watcher, err := newProcessExitWatcher(command.Process.Pid)
	if err != nil {
		return nil, err
	}
	return &ProcessSupervisor{
		command: command, tree: tree, watcher: watcher, waitDone: make(chan struct{}),
	}, nil
}

func (supervisor *ProcessSupervisor) Wait() error {
	supervisor.waitOnce.Do(func() {
		defer close(supervisor.waitDone)
		watchErr := supervisor.watcher.Wait()
		terminateErr := supervisor.tree.terminateAfterExit()
		closeErr := supervisor.watcher.Close()
		supervisor.waitErr = errors.Join(watchErr, terminateErr, closeErr, supervisor.command.Wait())
	})
	<-supervisor.waitDone
	return supervisor.waitErr
}

func (supervisor *ProcessSupervisor) Terminate() error {
	if supervisor == nil {
		return nil
	}
	return supervisor.tree.terminate()
}

func captureOwnedProcessTree(rootPID int) (ownedProcessTree, error) {
	identity, found, err := currentProcessIdentity(rootPID)
	if err != nil {
		return ownedProcessTree{}, err
	}
	if !found {
		return ownedProcessTree{}, syscall.ESRCH
	}
	return ownedProcessTree{rootPID: rootPID, rootIdentity: identity}, nil
}

func (tree ownedProcessTree) terminate() error {
	identity, found, err := currentProcessIdentity(tree.rootPID)
	if err != nil {
		return err
	}
	if found && identity != tree.rootIdentity {
		return nil
	}
	if !found {
		return nil
	}
	return tree.terminateLive()
}

func (tree ownedProcessTree) terminateAfterExit() error {
	members, err := processGroupMemberIDs(tree.rootPID)
	if err != nil {
		return err
	}
	var killErr error
	for _, pid := range members {
		if pid == tree.rootPID {
			continue
		}
		identity, found, identityErr := currentProcessIdentity(pid)
		if identityErr != nil {
			killErr = errors.Join(killErr, identityErr)
			continue
		}
		if !found {
			continue
		}
		currentIdentity, stillFound, identityErr := currentProcessIdentity(pid)
		if identityErr != nil {
			killErr = errors.Join(killErr, identityErr)
			continue
		}
		if !stillFound || currentIdentity != identity {
			continue
		}
		if err := syscall.Kill(pid, syscall.SIGKILL); err != nil && !errors.Is(err, syscall.ESRCH) {
			killErr = errors.Join(killErr, err)
		}
	}
	return killErr
}

func (tree ownedProcessTree) terminateLive() error {
	descendants, err := descendantProcessIDs(tree.rootPID)
	if err != nil {
		return err
	}
	type ownedDescendant struct {
		pid      int
		identity uint64
	}
	owned := make([]ownedDescendant, 0, len(descendants))
	for _, pid := range descendants {
		identity, found, identityErr := currentProcessIdentity(pid)
		if identityErr != nil {
			return identityErr
		}
		if found {
			owned = append(owned, ownedDescendant{pid: pid, identity: identity})
		}
	}
	var killErr error
	for index := len(owned) - 1; index >= 0; index-- {
		identity, found, identityErr := currentProcessIdentity(owned[index].pid)
		if identityErr != nil {
			killErr = errors.Join(killErr, identityErr)
			continue
		}
		if !found || identity != owned[index].identity {
			continue
		}
		if err := syscall.Kill(owned[index].pid, syscall.SIGKILL); err != nil && !errors.Is(err, syscall.ESRCH) {
			killErr = errors.Join(killErr, err)
		}
	}
	identity, found, err := currentProcessIdentity(tree.rootPID)
	if err != nil {
		return errors.Join(killErr, err)
	}
	if !found || identity != tree.rootIdentity {
		return killErr
	}
	if err := syscall.Kill(-tree.rootPID, syscall.SIGKILL); err != nil && !errors.Is(err, syscall.ESRCH) {
		killErr = errors.Join(killErr, err)
	}
	if err := syscall.Kill(tree.rootPID, syscall.SIGKILL); err != nil && !errors.Is(err, syscall.ESRCH) {
		killErr = errors.Join(killErr, err)
	}
	return killErr
}

func TerminateProcessTree(rootPID int) error {
	if rootPID <= 0 {
		return nil
	}
	tree, err := captureOwnedProcessTree(rootPID)
	if errors.Is(err, syscall.ESRCH) {
		return nil
	}
	if err != nil {
		return err
	}
	return tree.terminate()
}
