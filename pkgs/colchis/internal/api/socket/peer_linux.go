//go:build linux

package socket

import (
	"net"

	"golang.org/x/sys/unix"
)

func peerUID(connection *net.UnixConn) (uint32, error) {
	raw, err := connection.SyscallConn()
	if err != nil {
		return 0, err
	}
	var uid uint32
	var credentialError error
	if err := raw.Control(func(fileDescriptor uintptr) {
		credentials, err := unix.GetsockoptUcred(int(fileDescriptor), unix.SOL_SOCKET, unix.SO_PEERCRED)
		if err != nil {
			credentialError = err
			return
		}
		uid = credentials.Uid
	}); err != nil {
		return 0, err
	}
	return uid, credentialError
}
