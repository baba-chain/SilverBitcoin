// Copyright 2025 Silver Bitcoin Foundation

package server

import (
	"github.com/ethereum/go-ethereum/metrics"
)

var (
	totalActiveCapacityGauge = metrics.NewRegisteredGauge("vflux/server/active/capacity", nil)
	totalActiveCountGauge    = metrics.NewRegisteredGauge("vflux/server/active/count", nil)
	totalInactiveCountGauge  = metrics.NewRegisteredGauge("vflux/server/inactive/count", nil)

	clientConnectedMeter    = metrics.NewRegisteredMeter("vflux/server/clientEvent/connected", nil)
	clientActivatedMeter    = metrics.NewRegisteredMeter("vflux/server/clientEvent/activated", nil)
	clientDeactivatedMeter  = metrics.NewRegisteredMeter("vflux/server/clientEvent/deactivated", nil)
	clientDisconnectedMeter = metrics.NewRegisteredMeter("vflux/server/clientEvent/disconnected", nil)

	capacityQueryZeroMeter    = metrics.NewRegisteredMeter("vflux/server/capQueryZero", nil)
	capacityQueryNonZeroMeter = metrics.NewRegisteredMeter("vflux/server/capQueryNonZero", nil)
)
