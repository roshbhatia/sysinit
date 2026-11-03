package ty

import (
	"bytes"
	"os"
	"strconv"
	"strings"
)

func processArgv(pid int) ([]string, error) {
	data, err := os.ReadFile("/proc/" + strconv.Itoa(pid) + "/cmdline")
	if err != nil {
		return nil, err
	}
	return strings.Split(string(bytes.TrimSuffix(data, []byte{0})), "\x00"), nil
}
