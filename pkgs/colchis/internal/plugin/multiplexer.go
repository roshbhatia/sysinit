package plugin

import (
	"context"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

type AdapterRegistration struct {
	Manifest  AdapterManifest
	Invoke    InvocationHandler
	Reconcile ReconcileHandler
}

type adapterKey struct {
	id   string
	port domain.AdapterPort
}

type Multiplexer struct {
	manifests []AdapterManifest
	handlers  map[adapterKey]AdapterRegistration
}

func NewMultiplexer(registrations []AdapterRegistration) (*Multiplexer, error) {
	if len(registrations) == 0 {
		return nil, invalidProtocol("multiplexer", "adapter registrations are required")
	}
	multiplexer := &Multiplexer{
		manifests: make([]AdapterManifest, 0, len(registrations)),
		handlers:  make(map[adapterKey]AdapterRegistration, len(registrations)),
	}
	for _, registration := range registrations {
		if registration.Invoke == nil {
			return nil, invalidProtocol(registration.Manifest.ID, "adapter invocation handler is required")
		}
		key := adapterKey{id: registration.Manifest.ID, port: registration.Manifest.Port}
		if _, found := multiplexer.handlers[key]; found {
			return nil, invalidProtocol(registration.Manifest.ID, "adapter registration is duplicated")
		}
		multiplexer.handlers[key] = registration
		multiplexer.manifests = append(multiplexer.manifests, registration.Manifest)
	}
	return multiplexer, nil
}

func (multiplexer *Multiplexer) Manifests() []AdapterManifest {
	return append([]AdapterManifest(nil), multiplexer.manifests...)
}

func (multiplexer *Multiplexer) Invoke(
	ctx context.Context,
	envelope OperationEnvelope,
	emit EventEmitter,
) (OperationResult, error) {
	registration, found := multiplexer.handlers[adapterKey{id: envelope.AdapterID, port: envelope.Port}]
	if !found {
		return OperationResult{}, &domain.Error{
			Code: domain.ErrorCodeNotFound, Op: "route plugin operation", Resource: envelope.AdapterID,
			Message: "adapter registration does not exist",
		}
	}
	return registration.Invoke(ctx, envelope, emit)
}

func (multiplexer *Multiplexer) Reconcile(
	ctx context.Context,
	handles []HandleDescriptor,
) ([]ReconcileResult, error) {
	grouped := make(map[adapterKey][]HandleDescriptor)
	for _, handle := range handles {
		key := adapterKey{id: handle.AdapterID, port: handle.Port}
		grouped[key] = append(grouped[key], handle)
	}
	resolved := make(map[domain.AdapterHandleID]ReconcileResult, len(handles))
	for key, values := range grouped {
		registration, found := multiplexer.handlers[key]
		if !found || registration.Reconcile == nil {
			for _, handle := range values {
				resolved[handle.ID] = ReconcileResult{HandleID: handle.ID, State: ReconcileStateOrphaned}
			}
			continue
		}
		results, err := registration.Reconcile(ctx, values)
		if err != nil {
			return nil, err
		}
		for _, result := range results {
			resolved[result.HandleID] = result
		}
	}
	results := make([]ReconcileResult, 0, len(handles))
	for _, handle := range handles {
		result, found := resolved[handle.ID]
		if !found {
			result = ReconcileResult{HandleID: handle.ID, State: ReconcileStateOrphaned}
		}
		results = append(results, result)
	}
	return results, nil
}
