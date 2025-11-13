#!/bin/bash

# SilverBitcoin - Initialize All Nodes with Genesis
# This script initializes genesis block for all validator nodes

set -e

# Get the project root directory (2 levels up from scripts/setup/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔧 SilverBitcoin - Initialize Nodes                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if geth exists
GETH_BIN="./geth"
if [ ! -f "$GETH_BIN" ]; then
    # Try system geth
    if command -v geth &> /dev/null; then
        GETH_BIN="geth"
        echo -e "${YELLOW}Using system geth${NC}"
    else
        echo -e "${RED}❌ Geth binary not found!${NC}"
        echo -e "${YELLOW}Please build geth first:${NC}"
        echo -e "  cd Blockchain/node_src"
        echo -e "  go build -o geth ./cmd/geth"
        echo -e "  mv geth ../../"
        exit 1
    fi
else
    echo -e "${GREEN}Using local geth binary${NC}"
fi

# Check if genesis.json exists
GENESIS_FILE="genesis.json"
if [ ! -f "$GENESIS_FILE" ]; then
    if [ -f "Blockchain/genesis.json" ]; then
        GENESIS_FILE="Blockchain/genesis.json"
        echo -e "${YELLOW}Using genesis.json from Blockchain/genesis.json${NC}"
    elif [ -f "SilverBitcoin/genesis.json" ]; then
        GENESIS_FILE="SilverBitcoin/genesis.json"
        echo -e "${YELLOW}Using genesis.json from SilverBitcoin/genesis.json${NC}"
    else
        echo -e "${RED}❌ genesis.json not found!${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}Initializing genesis block for all nodes...${NC}"
echo ""

SUCCESS=0
FAILED=0

# Initialize each node
for i in {1..25}; do
    NODE_NUM=$(printf "%02d" $i)
    NODE_DIR="nodes/Node$NODE_NUM"
    
    if [ ! -d "$NODE_DIR" ]; then
        echo -e "${YELLOW}⚠️  Node$NODE_NUM directory not found, skipping...${NC}"
        ((FAILED++))
        continue
    fi
    
    # Check if already initialized
    if [ -d "$NODE_DIR/geth/chaindata" ]; then
        echo -e "${YELLOW}⚠️  Node$NODE_NUM already initialized, skipping...${NC}"
        continue
    fi
    
    echo -e "${CYAN}Initializing Node$NODE_NUM...${NC}"
    
    # Initialize genesis
    if $GETH_BIN --datadir "$NODE_DIR" init "$GENESIS_FILE" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Node$NODE_NUM initialized${NC}"
        ((SUCCESS++))
    else
        echo -e "${RED}❌ Failed to initialize Node$NODE_NUM${NC}"
        # Show error for debugging
        $GETH_BIN --datadir "$NODE_DIR" init "$GENESIS_FILE" 2>&1 | head -5
        ((FAILED++))
    fi
done

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   📊 Initialization Summary                                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Successfully initialized: $SUCCESS nodes${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED nodes${NC}"
fi
echo ""

if [ $SUCCESS -gt 0 ]; then
    echo -e "${GREEN}✅ Nodes are ready to start!${NC}"
    echo ""
    echo -e "${YELLOW}Next step:${NC}"
    echo -e "  ${CYAN}./start-all-nodes.sh${NC}"
else
    echo -e "${RED}❌ No nodes were initialized${NC}"
    exit 1
fi
