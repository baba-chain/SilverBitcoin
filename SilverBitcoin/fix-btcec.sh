#!/bin/bash

# Fix btcec v2 API changes in crypto files

cd SilverBitcoin/node_src

# Update signature_nocgo.go
sed -i 's/btcec\.PublicKey/btcec.PublicKey/g' crypto/signature_nocgo.go
sed -i 's/btcec\.PrivateKey/btcec.PrivateKey/g' crypto/signature_nocgo.go
sed -i 's/btcec\.S256()/btcec.S256()/g' crypto/signature_nocgo.go
sed -i 's/btcec\.RecoverCompact/ecdsa.RecoverCompact/g' crypto/signature_nocgo.go
sed -i 's/btcec\.SignCompact/ecdsa.SignCompact/g' crypto/signature_nocgo.go
sed -i 's/btcec\.Signature/ecdsa.Signature/g' crypto/signature_nocgo.go
sed -i 's/btcec\.ParsePubKey/btcec.ParsePubKey/g' crypto/signature_nocgo.go

# Update secp_fuzzer.go if exists
if [ -f "tests/fuzzers/secp256k1/secp_fuzzer.go" ]; then
    sed -i 's/"github\.com\/btcsuite\/btcd\/btcec"/"github.com\/btcsuite\/btcd\/btcec\/v2"/g' tests/fuzzers/secp256k1/secp_fuzzer.go
fi

echo "✅ btcec v2 API fixes applied"
