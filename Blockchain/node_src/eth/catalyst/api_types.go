// Copyright 2025 Silver Bitcoin Foundation

package catalyst

import (
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
)

//go:generate go run github.com/fjl/gencodec -type assembleBlockParams -field-override assembleBlockParamsMarshaling -out gen_blockparams.go

// Structure described at https://hackmd.io/T9x2mMA4S7us8tJwEB3FDQ
type assembleBlockParams struct {
	ParentHash common.Hash `json:"parentHash"    gencodec:"required"`
	Timestamp  uint64      `json:"timestamp"     gencodec:"required"`
}

// JSON type overrides for assembleBlockParams.
type assembleBlockParamsMarshaling struct {
	Timestamp hexutil.Uint64
}

//go:generate go run github.com/fjl/gencodec -type executableData -field-override executableDataMarshaling -out gen_ed.go

// Structure described at https://notes.ethereum.org/@n0ble/rayonism-the-merge-spec#Parameters1
type executableData struct {
	BlockHash    common.Hash    `json:"blockHash"     gencodec:"required"`
	ParentHash   common.Hash    `json:"parentHash"    gencodec:"required"`
	Miner        common.Address `json:"miner"         gencodec:"required"`
	StateRoot    common.Hash    `json:"stateRoot"     gencodec:"required"`
	Number       uint64         `json:"number"        gencodec:"required"`
	GasLimit     uint64         `json:"gasLimit"      gencodec:"required"`
	GasUsed      uint64         `json:"gasUsed"       gencodec:"required"`
	Timestamp    uint64         `json:"timestamp"     gencodec:"required"`
	ReceiptRoot  common.Hash    `json:"receiptsRoot"  gencodec:"required"`
	LogsBloom    []byte         `json:"logsBloom"     gencodec:"required"`
	Transactions [][]byte       `json:"transactions"  gencodec:"required"`
}

// JSON type overrides for executableData.
type executableDataMarshaling struct {
	Number       hexutil.Uint64
	GasLimit     hexutil.Uint64
	GasUsed      hexutil.Uint64
	Timestamp    hexutil.Uint64
	LogsBloom    hexutil.Bytes
	Transactions []hexutil.Bytes
}

type newBlockResponse struct {
	Valid bool `json:"valid"`
}

type genericResponse struct {
	Success bool `json:"success"`
}
