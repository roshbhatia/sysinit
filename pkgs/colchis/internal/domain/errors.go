package domain

import (
	"errors"
	"fmt"
)

type ErrorCode string

const (
	ErrorCodeInvalidArgument    ErrorCode = "invalid_argument"
	ErrorCodeNotFound           ErrorCode = "not_found"
	ErrorCodeConflict           ErrorCode = "conflict"
	ErrorCodeUnsupportedVersion ErrorCode = "unsupported_version"
	ErrorCodeBudgetExhausted    ErrorCode = "budget_exhausted"
	ErrorCodeUnauthorized       ErrorCode = "unauthorized"
	ErrorCodeIndeterminate      ErrorCode = "indeterminate"
	ErrorCodeInternal           ErrorCode = "internal"
)

func (code ErrorCode) Valid() bool {
	switch code {
	case ErrorCodeInvalidArgument,
		ErrorCodeNotFound,
		ErrorCodeConflict,
		ErrorCodeUnsupportedVersion,
		ErrorCodeBudgetExhausted,
		ErrorCodeUnauthorized,
		ErrorCodeIndeterminate,
		ErrorCodeInternal:
		return true
	default:
		return false
	}
}

type Error struct {
	Code     ErrorCode         `json:"code"`
	Op       string            `json:"op,omitempty"`
	Resource string            `json:"resource,omitempty"`
	Message  string            `json:"message"`
	Details  map[string]string `json:"details,omitempty"`
	Err      error             `json:"-"`
}

func (err *Error) Error() string {
	if err == nil {
		return "<nil>"
	}
	switch {
	case err.Op != "" && err.Resource != "":
		return fmt.Sprintf("%s %s: %s: %s", err.Op, err.Resource, err.Code, err.Message)
	case err.Op != "":
		return fmt.Sprintf("%s: %s: %s", err.Op, err.Code, err.Message)
	case err.Resource != "":
		return fmt.Sprintf("%s: %s: %s", err.Resource, err.Code, err.Message)
	default:
		return fmt.Sprintf("%s: %s", err.Code, err.Message)
	}
}

func (err *Error) Unwrap() error {
	if err == nil {
		return nil
	}
	return err.Err
}

func IsErrorCode(err error, code ErrorCode) bool {
	var domainError *Error
	return errors.As(err, &domainError) && domainError.Code == code
}
