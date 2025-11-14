#!/bin/bash

# Reth Quick Install - Download pre-built binary
# En hızlı kurulum yöntemi

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🦀 Reth Quick Install                                    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR/bin"
mkdir -p "$INSTALL_DIR"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

echo -e "${CYAN}Detected: $OS / $ARCH${NC}"

# Map architecture names
if [ "$ARCH" = "arm64" ]; then
    ARCH="aarch64"
fi

# Determine download URL based on OS
if [ "$OS" = "darwin" ]; then
    if [ "$ARCH" = "aarch64" ]; then
        # Apple Silicon (M1/M2/M3)
        DOWNLOAD_URL="https://github.com/paradigmxyz/reth/releases/download/v1.1.3/reth-v1.1.3-aarch64-apple-darwin.tar.gz"
    else
        # Intel Mac
        DOWNLOAD_URL="https://github.com/paradigmxyz/reth/releases/download/v1.1.3/reth-v1.1.3-x86_64-apple-darwin.tar.gz"
    fi
elif [ "$OS" = "linux" ]; then
    if [ "$ARCH" = "aarch64" ]; then
        DOWNLOAD_URL="https://github.com/paradigmxyz/reth/releases/download/v1.1.3/reth-v1.1.3-aarch64-unknown-linux-gnu.tar.gz"
    else
        DOWNLOAD_URL="https://github.com/paradigmxyz/reth/releases/download/v1.1.3/reth-v1.1.3-x86_64-unknown-linux-gnu.tar.gz"
    fi
else
    echo -e "${RED}Unsupported OS: $OS${NC}"
    exit 1
fi

echo -e "\n${CYAN}Downloading Reth binary...${NC}"
echo -e "${ORANGE}URL: $DOWNLOAD_URL${NC}"

cd "$INSTALL_DIR"

# Download
if ! curl -L -o reth.tar.gz "$DOWNLOAD_URL"; then
    echo -e "${RED}✗ Download failed${NC}"
    echo -e "${ORANGE}Try manual download from: https://github.com/paradigmxyz/reth/releases${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Downloaded${NC}"

# Extract
echo -e "${CYAN}Extracting...${NC}"
tar -xzf reth.tar.gz
rm reth.tar.gz

# Make executable
chmod +x reth

echo -e "${GREEN}✓ Installed to: $INSTALL_DIR/reth${NC}"

# Test
if ./reth --version; then
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✓ Reth Installation Complete                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${CYAN}Next step:${NC}"
    echo -e "  ${ORANGE}./start-reth-simple.sh${NC}"
else
    echo -e "${RED}✗ Installation failed${NC}"
    exit 1
fi
