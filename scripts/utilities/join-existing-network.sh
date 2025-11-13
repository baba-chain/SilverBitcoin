#!/bin/bash

# Join existing SilverBitcoin network
# Use this on a NEW server to connect to existing blockchain

set -e

# Get the project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔗 Join Existing SilverBitcoin Network                 ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Check if genesis.json exists
if [ ! -f "Blockchain/genesis.json" ]; then
    echo -e "${RED}Error: genesis.json not found!${NC}"
    echo -e "${ORANGE}Please copy genesis.json from your main server${NC}"
    exit 1
fi

# Get bootnode info
echo -e "\n${ORANGE}Enter bootnode enode URL:${NC}"
echo -e "${CYAN}Example: enode://abc123...@34.122.141.167:30304${NC}"
read -p "Bootnode: " BOOTNODE

if [ -z "$BOOTNODE" ]; then
    echo -e "${RED}Error: Bootnode required${NC}"
    exit 1
fi

# Create new node directory
NODE_DIR="nodes/NewNode"
mkdir -p "$NODE_DIR"

echo -e "\n${GREEN}Creating new wallet...${NC}"

# Generate new account
ACCOUNT_PASSWORD=""
echo "$ACCOUNT_PASSWORD" > "$NODE_DIR/password.txt"

# Create new private key
PRIVATE_KEY=$(openssl rand -hex 32)
echo "0x$PRIVATE_KEY" > "$NODE_DIR/private_key.txt"

# Initialize with existing genesis
echo -e "${GREEN}Initializing with existing genesis...${NC}"
geth --datadir "$NODE_DIR" init Blockchain/genesis.json

# Import account
echo -e "${GREEN}Importing account...${NC}"
TEMP_KEY=$(mktemp)
echo "$PRIVATE_KEY" > "$TEMP_KEY"
geth account import --datadir "$NODE_DIR" --password "$NODE_DIR/password.txt" "$TEMP_KEY" 2>&1 | grep -i "address" || true
rm "$TEMP_KEY"

# Get address
ADDRESS=$(geth account list --datadir "$NODE_DIR" 2>/dev/null | grep -oP '(?<={)[^}]+' | head -1)
echo "0x$ADDRESS" > "$NODE_DIR/address.txt"

echo -e "\n${GREEN}✅ New node created!${NC}"
echo -e "${CYAN}Address: 0x$ADDRESS${NC}"

# Start node
echo -e "\n${GREEN}Starting node...${NC}"

P2P_PORT=30304
HTTP_PORT=8546
WS_PORT=8547

tmux new-session -d -s "newnode" "geth \
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
    --bootnodes '$BOOTNODE' \
    --mine \
    --miner.etherbase 0x$ADDRESS \
    --unlock 0x$ADDRESS \
    --password '$NODE_DIR/password.txt' \
    --syncmode full \
    --gcmode archive \
    --allow-insecure-unlock \
    console"

sleep 3

echo -e "\n${GREEN}✅ Node started and connecting to network!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}To attach: ${ORANGE}tmux attach -t newnode${NC}"
echo -e "${CYAN}HTTP RPC:  ${ORANGE}http://localhost:$HTTP_PORT${NC}"
echo -e "${CYAN}Address:   ${ORANGE}0x$ADDRESS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${ORANGE}⚠️  Important:${NC}"
echo -e "   - This node will sync with existing blockchain"
echo -e "   - No new coins will be created"
echo -e "   - It will download blocks from other nodes"
echo -e "   - Check sync status: admin.peers in geth console"
