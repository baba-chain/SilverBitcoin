#!/bin/bash

# Reth (Rust Ethereum) Installation Script
# Reth'i kurar ve hazırlar

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🦀 Reth (Rust Ethereum) Installation                    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo -e "${ORANGE}Rust not found. Installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo -e "${GREEN}✓ Rust installed${NC}"
else
    echo -e "${GREEN}✓ Rust already installed${NC}"
    rustc --version
fi

# Check if Reth is already installed
if command -v reth &> /dev/null; then
    echo -e "${GREEN}✓ Reth already installed${NC}"
    reth --version
    exit 0
fi

echo -e "\n${CYAN}Choose installation method:${NC}"
echo -e "1. ${GREEN}Download pre-built binary (FAST - 1 minute)${NC}"
echo -e "2. ${ORANGE}Build from source with cargo (SLOW - 30-60 minutes)${NC}"
echo -e ""
read -p "Select [1/2]: " choice

case $choice in
    1)
        echo -e "\n${CYAN}Downloading pre-built Reth binary...${NC}"
        
        # Detect OS and architecture
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
        ARCH=$(uname -m)
        
        if [ "$ARCH" = "x86_64" ]; then
            ARCH="x86_64"
        elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            ARCH="aarch64"
        else
            echo -e "${RED}Unsupported architecture: $ARCH${NC}"
            exit 1
        fi
        
        # Get latest release
        LATEST_URL="https://github.com/paradigmxyz/reth/releases/latest/download/reth-v1.1.3-${ARCH}-unknown-${OS}-gnu.tar.gz"
        
        echo -e "${CYAN}Downloading from: $LATEST_URL${NC}"
        
        cd /tmp
        curl -L -o reth.tar.gz "$LATEST_URL" || {
            echo -e "${RED}Download failed. Trying alternative method...${NC}"
            # Fallback to cargo install
            cargo install --git https://github.com/paradigmxyz/reth --locked reth
            exit 0
        }
        
        tar -xzf reth.tar.gz
        
        # Install to cargo bin directory
        mkdir -p "$HOME/.cargo/bin"
        mv reth "$HOME/.cargo/bin/"
        chmod +x "$HOME/.cargo/bin/reth"
        rm reth.tar.gz
        
        echo -e "${GREEN}✓ Binary installed${NC}"
        ;;
    2)
        echo -e "\n${CYAN}Building Reth from source...${NC}"
        echo -e "${ORANGE}This will take 30-60 minutes...${NC}"
        echo -e "${ORANGE}Go grab a coffee ☕${NC}"
        
        # Clone and build
        cd /tmp
        if [ -d "reth" ]; then
            rm -rf reth
        fi
        
        git clone https://github.com/paradigmxyz/reth.git
        cd reth
        
        echo -e "\n${CYAN}Running: cargo build --release${NC}"
        cargo build --release
        
        # Install binary
        mkdir -p "$HOME/.cargo/bin"
        cp target/release/reth "$HOME/.cargo/bin/"
        
        # Cleanup
        cd ..
        rm -rf reth
        
        echo -e "${GREEN}✓ Built and installed${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

if command -v reth &> /dev/null; then
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✓ Reth Installation Complete                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${CYAN}Reth version:${NC}"
    reth --version
else
    echo -e "${RED}✗ Reth installation failed${NC}"
    exit 1
fi
