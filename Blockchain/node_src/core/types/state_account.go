// Copyright 2025 Silver Bitcoin Foundation

package types

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

// StateAccount is the Ethereum consensus representation of accounts.
// These objects are stored in the main account trie.
type StateAccount struct {
	Nonce    uint64
	Balance  *big.Int
	Root     common.Hash // merkle root of the storage trie
	CodeHash []byte
}
