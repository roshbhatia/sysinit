package domain

type Budgets struct {
	MaxConcurrentNodes       uint32 `json:"maxConcurrentNodes"`
	MaxConcurrentProcesses   uint32 `json:"maxConcurrentProcesses"`
	MaxEventBytes            uint64 `json:"maxEventBytes"`
	MaxEventsPerSecond       uint32 `json:"maxEventsPerSecond"`
	MaxStateBytes            uint64 `json:"maxStateBytes"`
	EmergencyReserveBytes    uint64 `json:"emergencyReserveBytes"`
	MaxSnapshotBytes         uint64 `json:"maxSnapshotBytes"`
	MaxMaterializedSnapshots uint32 `json:"maxMaterializedSnapshots"`
	MaxVerificationSeconds   uint32 `json:"maxVerificationSeconds"`
}

func DefaultBudgets() Budgets {
	return Budgets{
		MaxConcurrentNodes:       8,
		MaxConcurrentProcesses:   8,
		MaxEventBytes:            1 << 20,
		MaxEventsPerSecond:       1000,
		MaxStateBytes:            8 << 30,
		EmergencyReserveBytes:    64 << 20,
		MaxSnapshotBytes:         8 << 30,
		MaxMaterializedSnapshots: 4,
		MaxVerificationSeconds:   3600,
	}
}

func (budgets Budgets) Validate() error {
	values := []struct {
		name  string
		value uint64
	}{
		{name: "maxConcurrentNodes", value: uint64(budgets.MaxConcurrentNodes)},
		{name: "maxConcurrentProcesses", value: uint64(budgets.MaxConcurrentProcesses)},
		{name: "maxEventBytes", value: budgets.MaxEventBytes},
		{name: "maxEventsPerSecond", value: uint64(budgets.MaxEventsPerSecond)},
		{name: "maxStateBytes", value: budgets.MaxStateBytes},
		{name: "emergencyReserveBytes", value: budgets.EmergencyReserveBytes},
		{name: "maxSnapshotBytes", value: budgets.MaxSnapshotBytes},
		{name: "maxMaterializedSnapshots", value: uint64(budgets.MaxMaterializedSnapshots)},
		{name: "maxVerificationSeconds", value: uint64(budgets.MaxVerificationSeconds)},
	}
	for _, entry := range values {
		if entry.value == 0 {
			return &Error{
				Code:     ErrorCodeInvalidArgument,
				Resource: "budgets",
				Message:  entry.name + " must be greater than zero",
			}
		}
	}
	if budgets.EmergencyReserveBytes >= budgets.MaxStateBytes {
		return &Error{
			Code:     ErrorCodeInvalidArgument,
			Resource: "budgets",
			Message:  "emergencyReserveBytes must be less than maxStateBytes",
		}
	}
	if budgets.MaxEventBytes > budgets.MaxStateBytes-budgets.EmergencyReserveBytes {
		return &Error{
			Code:     ErrorCodeInvalidArgument,
			Resource: "budgets",
			Message:  "maxEventBytes exceeds usable state capacity",
		}
	}
	if budgets.MaxSnapshotBytes >= uint64(1<<63-1) {
		return &Error{
			Code:     ErrorCodeInvalidArgument,
			Resource: "budgets",
			Message:  "maxSnapshotBytes exceeds the supported size",
		}
	}
	return nil
}
