package socket

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"net/url"
	"strconv"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

const maxClientResponseBytes = 8 << 20

type Client struct {
	http *http.Client
}

func NewClient(path string) (*Client, error) {
	if path == "" {
		return nil, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "socket client", Message: "socket path is empty",
		}
	}
	transport := &http.Transport{
		DialContext: func(ctx context.Context, _, _ string) (net.Conn, error) {
			return (&net.Dialer{}).DialContext(ctx, "unix", path)
		},
	}
	return &Client{http: &http.Client{Transport: transport}}, nil
}

func (client *Client) Close() {
	if client != nil && client.http != nil {
		client.http.CloseIdleConnections()
	}
}

func (client *Client) Command(
	ctx context.Context,
	request domain.CommandRequest,
) (domain.CommandRecord, error) {
	payload, err := json.Marshal(request)
	if err != nil {
		return domain.CommandRecord{}, err
	}
	httpRequest, err := http.NewRequestWithContext(
		ctx, http.MethodPost, "http://colchis/v1/commands", bytes.NewReader(payload),
	)
	if err != nil {
		return domain.CommandRecord{}, err
	}
	httpRequest.Header.Set("Content-Type", "application/json")
	response, err := client.http.Do(httpRequest)
	if err != nil {
		return domain.CommandRecord{}, err
	}
	defer response.Body.Close()
	body, err := io.ReadAll(io.LimitReader(response.Body, maxClientResponseBytes+1))
	if err != nil {
		return domain.CommandRecord{}, err
	}
	if len(body) > maxClientResponseBytes {
		return domain.CommandRecord{}, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Resource: "command response", Message: "response exceeds its byte limit",
		}
	}
	if response.StatusCode != http.StatusAccepted {
		return domain.CommandRecord{}, decodeClientError(response.StatusCode, body)
	}
	var decoded commandResponse
	if err := json.Unmarshal(body, &decoded); err != nil {
		return domain.CommandRecord{}, err
	}
	return decoded.Command, nil
}

func (client *Client) Query(
	ctx context.Context,
	request QueryRequest,
) (json.RawMessage, error) {
	payload, err := json.Marshal(request)
	if err != nil {
		return nil, err
	}
	httpRequest, err := http.NewRequestWithContext(
		ctx, http.MethodPost, "http://colchis/v1/queries", bytes.NewReader(payload),
	)
	if err != nil {
		return nil, err
	}
	httpRequest.Header.Set("Content-Type", "application/json")
	response, err := client.http.Do(httpRequest)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()
	body, err := io.ReadAll(io.LimitReader(response.Body, maxClientResponseBytes+1))
	if err != nil {
		return nil, err
	}
	if len(body) > maxClientResponseBytes {
		return nil, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Resource: "query response", Message: "response exceeds its byte limit",
		}
	}
	if response.StatusCode != http.StatusOK {
		return nil, decodeClientError(response.StatusCode, body)
	}
	var decoded queryResponse
	if err := json.Unmarshal(body, &decoded); err != nil {
		return nil, err
	}
	return decoded.Result, nil
}

func (client *Client) Events(
	ctx context.Context,
	after domain.EventCursor,
	limit uint32,
) ([]domain.EventEnvelope, error) {
	query := url.Values{}
	query.Set("after", strconv.FormatUint(uint64(after), 10))
	query.Set("limit", strconv.FormatUint(uint64(limit), 10))
	httpRequest, err := http.NewRequestWithContext(
		ctx, http.MethodGet, "http://colchis/v1/events?"+query.Encode(), nil,
	)
	if err != nil {
		return nil, err
	}
	response, err := client.http.Do(httpRequest)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		body, readErr := io.ReadAll(io.LimitReader(response.Body, maxClientResponseBytes+1))
		if readErr != nil {
			return nil, readErr
		}
		return nil, decodeClientError(response.StatusCode, body)
	}
	scanner := bufio.NewScanner(response.Body)
	scanner.Buffer(make([]byte, 4096), maxClientResponseBytes)
	events := make([]domain.EventEnvelope, 0)
	for scanner.Scan() {
		var event domain.EventEnvelope
		if err := json.Unmarshal(scanner.Bytes(), &event); err != nil {
			return nil, err
		}
		events = append(events, event)
	}
	return events, scanner.Err()
}

func decodeClientError(status int, payload []byte) error {
	var response errorResponse
	if err := json.Unmarshal(payload, &response); err == nil && response.Error != nil {
		return response.Error
	}
	return &domain.Error{
		Code: domain.ErrorCodeInternal, Op: "call broker", Resource: strconv.Itoa(status),
		Message: "broker returned an invalid error response", Err: errors.New(string(payload)),
	}
}
