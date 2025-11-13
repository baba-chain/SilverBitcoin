#!/bin/bash

# SilverBitcoin - Complete Blockchain Setup
# This script does EVERYTHING: system update, dependencies, build, generate keys, initialize, start

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
echo -e "  0. Check and install system dependencies"
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

# Step 0: Check and Install Dependencies
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 0/6: Checking System Dependencies                   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
    echo -e "${YELLOW}Running with sudo...${NC}"
else
    SUDO=""
    echo -e "${YELLOW}Running as root...${NC}"
fi

# Check Go version
GO_VERSION=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
GO_REQUIRED="1.21"

if [ -z "$GO_VERSION" ]; then
    echo -e "${YELLOW}Go not found. Installing...${NC}"
    $SUDO apt update -qq
    $SUDO apt install -y golang-go
else
    echo -e "${GREEN}✓ Go $GO_VERSION installed${NC}"
fi

# Check other dependencies
PACKAGES="git build-essential tmux curl wget openssl libgmp-dev libssl-dev pkg-config"
MISSING_PACKAGES=""

for pkg in $PACKAGES; do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        MISSING_PACKAGES="$MISSING_PACKAGES $pkg"
    fi
done

if [ ! -z "$MISSING_PACKAGES" ]; then
    echo -e "${YELLOW}Installing missing packages:$MISSING_PACKAGES${NC}"
    $SUDO apt update -qq
    $SUDO apt install -y $MISSING_PACKAGES
    echo -e "${GREEN}✓ Packages installed${NC}"
else
    echo -e "${GREEN}✓ All required packages installed${NC}"
fi

# Copy genesis.json if not exists
if [ ! -f "genesis.json" ] && [ -f "SilverBitcoin/genesis.json" ]; then
    echo -e "${YELLOW}Copying genesis.json...${NC}"
    cp SilverBitcoin/genesis.json .
    echo -e "${GREEN}✓ Genesis.json copied${NC}"
fi

echo ""

# Step 1: Build Geth
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Step 1/6: Building Geth                                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ ! -f "geth" ]; then
    if [ -d "SilverBitcoin/node_src" ]; then
        echo -e "${YELLOW}Building Geth from source...${NC}"
        cd SilverBitcoin/node_src
        
        # Download Go modules
        echo -e "${YELLOW}Downloading Go modules...${NC}"
        go mod download
        go mod tidy
        
        # Build Geth
        echo -e "${YELLOW}Compiling Geth (this may take a few minutes)...${NC}"
        go build -o geth ./cmd/geth
        
        if [ -f "geth" ]; then
            mv geth ../../
            cd ../..
            chmod +x geth
            echo -e "${GREEN}✅ Geth built successfully${NC}"
        else
            echo -e "${RED}❌ Geth build failed${NC}"
            cd ../..
            exit 1
        fi
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
echo -e "${CYAN}║   Step 2/6: Generating Validator Keys                      ║${NC}"
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
echo -e "${CYAN}║   Step 4/6: Initializing Nodes                             ║${NC}"
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
echo -e "${CYAN}║   Step 5/6: Starting Validator Nodes                       ║${NC}"
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
