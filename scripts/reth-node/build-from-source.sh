#!/bin/bash

# Reth - Build from Source
# Kaynak koddan derler (30-60 dakika sürer)

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🦀 Building Reth from Source                             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Check Rust
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}✗ Rust not found${NC}"
    echo -e "${ORANGE}Installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

echo -e "\n${ORANGE}⚠️  WARNING: This will take 30-60 minutes!${NC}"
echo -e "${ORANGE}⚠️  Make sure you have at least 10GB free disk space${NC}"
echo -e ""
read -p "Continue? [y/N]: " confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo -e "${RED}Cancelled${NC}"
    exit 0
fi

BUILD_DIR="/tmp/reth-build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Clone repository
if [ -d "reth" ]; then
    echo -e "${ORANGE}Removing old build directory...${NC}"
    rm -rf reth
fi

echo -e "\n${CYAN}Step 1/3: Cloning repository...${NC}"
git clone https://github.com/paradigmxyz/reth.git
cd reth

echo -e "\n${CYAN}Step 2/3: Building (this takes a while)...${NC}"
echo -e "${ORANGE}Started at: $(date)${NC}"
START_TIME=$(date +%s)

cargo build --release

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))

echo -e "\n${GREEN}✓ Build completed in $MINUTES minutes${NC}"

echo -e "\n${CYAN}Step 3/3: Installing binary...${NC}"
mkdir -p "$HOME/.cargo/bin"
cp target/release/reth "$HOME/.cargo/bin/"
chmod +x "$HOME/.cargo/bin/reth"

# Cleanup
cd ..
echo -e "\n${CYAN}Cleaning up build directory...${NC}"
rm -rf reth

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Reth Built and Installed Successfully                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"

reth --version

echo -e "\n${CYAN}Next steps:${NC}"
echo -e "  ${ORANGE}./start-reth-node.sh${NC}"
