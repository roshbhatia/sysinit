package ty

import (
	"bytes"
	"encoding/binary"
	"fmt"

	"golang.org/x/sys/unix"
)

func processArgv(pid int) ([]string, error) {
	data, err := unix.SysctlRaw("kern.procargs2", pid)
	if err != nil {
		return nil, err
	}
	if len(data) < 4 {
		return nil, fmt.Errorf("process %d has no argument record", pid)
	}
	count := int(binary.NativeEndian.Uint32(data[:4]))
	data = data[4:]
	end := bytes.IndexByte(data, 0)
	if end < 0 {
		return nil, fmt.Errorf("process %d has no executable record", pid)
	}
	data = bytes.TrimLeft(data[end:], "\x00")
	args := make([]string, 0, count)
	for len(args) < count {
		end = bytes.IndexByte(data, 0)
		if end < 0 {
			return nil, fmt.Errorf("process %d has an incomplete argument record", pid)
		}
		args = append(args, string(data[:end]))
		data = data[end+1:]
	}
	return args, nil
}
