#!/bin/bash

# SilverBitcoin Network Setup
# Node'ları durdur, enode'ları topla, yeniden başlat

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🌐 SilverBitcoin Network Setup                          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Adım 1: Enode'ları topla (node'lar çalışıyorken)
echo -e "\n${CYAN}Step 1: Collecting enode addresses...${NC}"
if ./collect-enodes.sh; then
    echo -e "${GREEN}✓ Enodes collected${NC}"
else
    echo -e "${RED}✗ Failed to collect enodes${NC}"
    echo -e "${ORANGE}Make sure nodes are running first!${NC}"
    exit 1
fi

# Adım 2: Tüm node'ları durdur
echo -e "\n${CYAN}Step 2: Stopping all nodes...${NC}"
./stop-all-nodes.sh
sleep 3

# Adım 3: Discovery'yi aktif et
echo -e "\n${CYAN}Step 3: Enabling discovery...${NC}"
./enable-discovery.sh

# Adım 4: Tüm node'ları başlat
echo -e "\n${CYAN}Step 4: Starting all nodes...${NC}"
./start-all-nodes.sh

# Adım 5: Durum kontrolü
echo -e "\n${CYAN}Step 5: Checking node status...${NC}"
sleep 5
./node-status.sh

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Network Setup Complete                                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${CYAN}Nodes should now be discovering each other!${NC}"
echo -e "${CYAN}Wait 30-60 seconds and check peer count with:${NC}"
echo -e "${ORANGE}./node-status.sh${NC}"
