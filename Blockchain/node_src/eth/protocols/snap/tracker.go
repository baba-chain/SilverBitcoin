// Copyright 2025 Silver Bitcoin Foundation

package snap

import (
	"time"

	"github.com/ethereum/go-ethereum/p2p/tracker"
)

// requestTracker is a singleton tracker for request times.
var requestTracker = tracker.New(ProtocolName, time.Minute)
