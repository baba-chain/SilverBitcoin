#!/bin/bash

# SilverBitcoin Node Starter
# Usage: ./start-node.sh <node_number>

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}Error: Node number required${NC}"
    echo -e "Usage: $0 <node_number>"
    exit 1
fi

NODE_NUM=$1
NODE_DIR="nodes/Node$(printf "%02d" $NODE_NUM)"

if [ ! -d "$NODE_DIR" ]; then
    echo -e "${RED}Error: Node directory not found: $NODE_DIR${NC}"
    exit 1
fi

if tmux has-session -t "node$NODE_NUM" 2>/dev/null; then
    echo -e "${ORANGE}Node$NODE_NUM is already running${NC}"
    echo -e "To attach: ${CYAN}tmux attach -t node$NODE_NUM${NC}"
    exit 0
fi

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🚀 Starting SilverBitcoin Node$(printf "%02d" $NODE_NUM)                        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

ADDRESS=$(cat "$NODE_DIR/address.txt" 2>/dev/null || echo "unknown")
echo -e "${GREEN}Address: $ADDRESS${NC}"

# Initialize genesis if needed
if [ ! -d "$NODE_DIR/geth" ]; then
    echo -e "${ORANGE}Initializing genesis...${NC}"
    geth --datadir "$NODE_DIR" init SilverBitcoin/genesis.json
    echo -e "${GREEN}✓ Genesis initialized${NC}"
fi

# Create password file
PASSWORD_FILE="$NODE_DIR/password.txt"
if [ ! -f "$PASSWORD_FILE" ]; then
    echo "" > "$PASSWORD_FILE"
fi

# Import account if needed
KEYSTORE_DIR="$NODE_DIR/keystore"
if [ ! -d "$KEYSTORE_DIR" ] || [ -z "$(ls -A $KEYSTORE_DIR 2>/dev/null)" ]; then
    echo -e "${ORANGE}Importing account...${NC}"
    TEMP_KEY=$(mktemp)
    cat "$NODE_DIR/private_key.txt" | sed 's/^0x//' > "$TEMP_KEY"
    geth account import --datadir "$NODE_DIR" --password "$PASSWORD_FILE" "$TEMP_KEY" 2>&1 | grep -i "address" || true
    rm "$TEMP_KEY"
    echo -e "${GREEN}✓ Account imported${NC}"
fi

# Start node
echo -e "${GREEN}Starting node...${NC}"

P2P_PORT=$((30303 + NODE_NUM))
HTTP_PORT=$((8545 + NODE_NUM))
WS_PORT=$((8546 + NODE_NUM))

if [ "$NODE_NUM" -eq 25 ]; then
    # Treasury node - no mining
    echo -e "${ORANGE}Treasury node - no mining${NC}"
    tmux new-session -d -s "node$NODE_NUM" "cd '$PWD' && geth \
        --datadir '$NODE_DIR' \
        --networkid 5200 \
        --port $P2P_PORT \
        --http \
        --http.addr 0.0.0.0 \
        --http.port $HTTP_PORT \
        --http.api eth,net,web3,personal,admin \
        --http.corsdomain '*' \
        --ws \
        --ws.addr 0.0.0.0 \
        --ws.port $WS_PORT \
        --ws.api eth,net,web3,personal,admin \
        --ws.origins '*' \
        --syncmode full \
        --gcmode archive \
        --allow-insecure-unlock \
        console"
else
    # Validator node - with mining
    tmux new-session -d -s "node$NODE_NUM" "cd '$PWD' && geth \
        --datadir '$NODE_DIR' \
        --networkid 5200 \
        --port $P2P_PORT \
        --http \
        --http.addr 0.0.0.0 \
        --http.port $HTTP_PORT \
        --http.api eth,net,web3,personal,admin,miner \
        --http.corsdomain '*' \
        --ws \
        --ws.addr 0.0.0.0 \
        --ws.port $WS_PORT \
        --ws.api eth,net,web3,personal,admin,miner \
        --ws.origins '*' \
        --mine \
        --miner.etherbase $ADDRESS \
        --unlock $ADDRESS \
        --password '$PASSWORD_FILE' \
        --syncmode full \
        --gcmode archive \
        --allow-insecure-unlock \
        console"
fi

sleep 2

if tmux has-session -t "node$NODE_NUM" 2>/dev/null; then
    echo -e "${GREEN}✓ Node$NODE_NUM started successfully${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}To attach: ${ORANGE}tmux attach -t node$NODE_NUM${NC}"
    echo -e "${CYAN}To detach: ${ORANGE}Ctrl+B then D${NC}"
    echo -e "${CYAN}HTTP RPC:  ${ORANGE}http://localhost:$HTTP_PORT${NC}"
    echo -e "${CYAN}WS RPC:    ${ORANGE}ws://localhost:$WS_PORT${NC}"
    echo -e "${CYAN}P2P Port:  ${ORANGE}$P2P_PORT${NC}"
else
    echo -e "${RED}✗ Failed to start node$NODE_NUM${NC}"
    exit 1
fi
