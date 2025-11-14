#!/bin/bash

# Reth - Run with Cargo (Development Mode)
# cargo run ile direkt çalıştırır (her seferinde compile eder)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🦀 Running Reth with Cargo                               ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Check Rust
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}✗ Rust not found${NC}"
    exit 1
fi

RETH_SOURCE="/tmp/reth-source"
RETH_DIR="$PROJECT_ROOT/reth-data"

# Clone if not exists
if [ ! -d "$RETH_SOURCE" ]; then
    echo -e "${CYAN}Cloning Reth repository...${NC}"
    git clone https://github.com/paradigmxyz/reth.git "$RETH_SOURCE"
fi

cd "$RETH_SOURCE"

# Update to latest
echo -e "${CYAN}Updating to latest version...${NC}"
git pull

# Create data directory
mkdir -p "$RETH_DIR"

# Initialize genesis if needed
if [ ! -d "$RETH_DIR/db" ]; then
    echo -e "${ORANGE}Initializing genesis...${NC}"
    cargo run --release -- init \
        --datadir "$RETH_DIR" \
        --chain "$SCRIPT_DIR/genesis-reth.json"
    echo -e "${GREEN}✓ Genesis initialized${NC}"
fi

echo -e "\n${CYAN}Starting Reth with cargo run...${NC}"
echo -e "${ORANGE}Note: First run will compile (takes time)${NC}"

HTTP_PORT=9545
WS_PORT=9546
P2P_PORT=30403

# Run with cargo
cargo run --release -- node \
    --datadir "$RETH_DIR" \
    --chain "$SCRIPT_DIR/genesis-reth.json" \
    --http \
    --http.addr 0.0.0.0 \
    --http.port $HTTP_PORT \
    --http.api eth,net,web3,debug,trace \
    --http.corsdomain '*' \
    --ws \
    --ws.addr 0.0.0.0 \
    --ws.port $WS_PORT \
    --ws.api eth,net,web3,debug,trace \
    --ws.origins '*' \
    --port $P2P_PORT
