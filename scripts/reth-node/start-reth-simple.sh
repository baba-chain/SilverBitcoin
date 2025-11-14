#!/bin/bash

# Reth Simple Starter
# İndirilen binary ile node başlatır

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🦀 Starting Reth Node (Simple)                          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Check if binary exists
RETH_BIN="$SCRIPT_DIR/bin/reth"
if [ ! -f "$RETH_BIN" ]; then
    echo -e "${RED}✗ Reth binary not found${NC}"
    echo -e "${ORANGE}Run: ./quick-install.sh${NC}"
    exit 1
fi

# Create data directory
RETH_DIR="$PROJECT_ROOT/reth-data"
mkdir -p "$RETH_DIR"

# Check if already running
if tmux has-session -t "reth-node" 2>/dev/null; then
    echo -e "${ORANGE}Reth node is already running${NC}"
    echo -e "To attach: ${CYAN}tmux attach -t reth-node${NC}"
    exit 0
fi

# Initialize genesis if needed
if [ ! -d "$RETH_DIR/db" ]; then
    echo -e "${ORANGE}Initializing genesis...${NC}"
    "$RETH_BIN" init \
        --datadir "$RETH_DIR" \
        --chain "$SCRIPT_DIR/genesis-reth.json"
    echo -e "${GREEN}✓ Genesis initialized${NC}"
fi

# Start node
echo -e "${GREEN}Starting Reth node...${NC}"

HTTP_PORT=9545
WS_PORT=9546
P2P_PORT=30403
AUTH_PORT=8651

tmux new-session -d -s "reth-node" "'$RETH_BIN' node \
    --datadir '$RETH_DIR' \
    --chain '$SCRIPT_DIR/genesis-reth.json' \
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
    --port $P2P_PORT \
    --authrpc.port $AUTH_PORT \
    --authrpc.addr 0.0.0.0 \
    --log.file.directory '$RETH_DIR/logs' \
    2>&1 | tee '$RETH_DIR/reth.log'"

sleep 3

if tmux has-session -t "reth-node" 2>/dev/null; then
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✓ Reth Node Started Successfully                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${CYAN}Connection Info:${NC}"
    echo -e "  HTTP RPC:  ${ORANGE}http://localhost:$HTTP_PORT${NC}"
    echo -e "  WS RPC:    ${ORANGE}ws://localhost:$WS_PORT${NC}"
    echo -e "  P2P Port:  ${ORANGE}$P2P_PORT${NC}"
    echo -e "\n${CYAN}Commands:${NC}"
    echo -e "  Attach:    ${ORANGE}tmux attach -t reth-node${NC}"
    echo -e "  Detach:    ${ORANGE}Ctrl+B then D${NC}"
    echo -e "  Stop:      ${ORANGE}./stop-reth-node.sh${NC}"
    echo -e "  Status:    ${ORANGE}./reth-status.sh${NC}"
    echo -e "\n${CYAN}Test RPC:${NC}"
    echo -e "  ${ORANGE}curl -X POST -H 'Content-Type: application/json' \\${NC}"
    echo -e "    ${ORANGE}--data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}' \\${NC}"
    echo -e "    ${ORANGE}http://localhost:$HTTP_PORT${NC}"
else
    echo -e "${RED}✗ Failed to start Reth node${NC}"
    exit 1
fi
