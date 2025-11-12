#!/bin/bash

# SilverBitcoin - Complete Blockchain Setup
# This script does EVERYTHING: build, generate keys, update genesis, initialize, start

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🚀 SilverBitcoin - Complete Blockchain Setup            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This will:${NC}"
echo -e "  1. Build Geth binary"
echo -e "  2. Generate validator private keys"
echo -e "  3. Update genesis.json with new addresses"
echo -e "  4. Initialize genesis for all nodes"
echo -e "  5. Start all validator nodes"
echo ""
echo -e "${RED}⚠️  This should be run ONLY on the server!${NC}"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ] && [ "$confirm" != "y" ]; then
    echo -e "${RED}❌ Cancelled.${NC}"
    exit 0
fi

echo ""

# Step 1: Build Geth
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 1/5: Building Geth                                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ ! -f "geth" ]; then
    if [ -d "SilverBitcoin/node_src" ]; then
        echo -e "${YELLOW}Building Geth from source...${NC}"
        cd SilverBitcoin/node_src
        go mod download
        go build -o geth ./cmd/geth
        mv geth ../../
        cd ../..
        chmod +x geth
        echo -e "${GREEN}✅ Geth built successfully${NC}"
    else
        echo -e "${RED}❌ Geth source not found at SilverBitcoin/node_src${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Geth binary already exists${NC}"
fi

echo ""

# Step 2: Generate Keys
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 2/5: Generating Validator Keys                      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "generate-node-keys.sh" ]; then
    chmod +x generate-node-keys.sh
    # Auto-confirm for generate-node-keys.sh
    echo "yes" | ./generate-node-keys.sh
else
    echo -e "${RED}❌ generate-node-keys.sh not found${NC}"
    exit 1
fi

echo ""

# Step 3: Genesis is already updated by generate-node-keys.sh
echo -e "${GREEN}✅ Genesis.json updated with validator addresses${NC}"
echo ""

# Step 4: Initialize Nodes
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 4/5: Initializing Nodes                             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "initialize-nodes.sh" ]; then
    chmod +x initialize-nodes.sh
    ./initialize-nodes.sh
else
    echo -e "${RED}❌ initialize-nodes.sh not found${NC}"
    exit 1
fi

echo ""

# Step 5: Start Nodes
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 5/5: Starting Validator Nodes                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "start-all-nodes.sh" ]; then
    chmod +x start-all-nodes.sh
    ./start-all-nodes.sh
else
    echo -e "${RED}❌ start-all-nodes.sh not found${NC}"
    exit 1
fi

echo ""

# Final Summary
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ✅ Blockchain Setup Complete!                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}🎉 SilverBitcoin blockchain is now running!${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  Check status:    ${CYAN}./node-status.sh${NC}"
echo -e "  View nodes:      ${CYAN}tmux ls${NC}"
echo -e "  Attach to node:  ${CYAN}tmux attach -t node1${NC}"
echo -e "  Stop nodes:      ${CYAN}./stop-all-nodes.sh${NC}"
echo ""
echo -e "${YELLOW}RPC Endpoint:${NC}"
echo -e "  ${CYAN}http://$(hostname -I | awk '{print $1}'):8546${NC}"
echo ""
echo -e "${YELLOW}Chain Info:${NC}"
echo -e "  Chain ID: ${CYAN}5200${NC}"
echo -e "  Symbol: ${CYAN}SBTC${NC}"
