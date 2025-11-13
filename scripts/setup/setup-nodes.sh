#!/bin/bash
# SilverBitcoin Node Setup Script (Safe Version)
# Creates node directory structure WITHOUT private keys
# Private keys should be generated on the server using generate-node-keys.sh

set -e

# Get the project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

echo '🖥️  SilverBitcoin Node Setup (Safe)'
echo '===================================='
echo ''
echo '⚠️  This script creates node directories WITHOUT private keys.'
echo '⚠️  Private keys must be generated on the server for security.'
echo ''

# Create node directories with placeholder addresses
for i in {1..25}; do
    NODE_NUM=$(printf "%02d" $i)
    NODE_DIR="nodes/Node$NODE_NUM"
    
    mkdir -p "$NODE_DIR"
    
    # Create placeholder files
    echo "PLACEHOLDER - Generate keys on server" > "$NODE_DIR/address.txt"
    echo "Balance: 2,000,000 SBTC (to be allocated in genesis)" > "$NODE_DIR/info.txt"
    echo "Run generate-node-keys.sh on the server to create actual keys" > "$NODE_DIR/README.txt"
    
    echo "✅ Node$NODE_NUM directory created"
done

echo ''
echo '✅ All node directories created'
echo ''
echo '📋 Next steps ON THE SERVER:'
echo '  1. Clone repository: git clone https://github.com/baba-chain/SilverBitcoin.git'
echo '  2. Build geth: cd Blockchain/node_src && go build -o geth ./cmd/geth'
echo '  3. Generate keys: scripts/setup/generate-node-keys.sh'
echo '  4. Update genesis.json with new addresses'
echo '  5. Initialize genesis for each node'
echo '  6. Start nodes: scripts/node-management/start-all-nodes.sh'
echo ''
echo '⚠️  SECURITY: Never commit private keys to GitHub!'
