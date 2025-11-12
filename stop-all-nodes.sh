#!/bin/bash

# Stop all SilverBitcoin nodes

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🛑 Stopping All SilverBitcoin Nodes                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

STOPPED=0
NOT_RUNNING=0

for i in {1..25}; do
    if tmux has-session -t "node$i" 2>/dev/null; then
        echo -e "${ORANGE}Stopping Node$i...${NC}"
        tmux kill-session -t "node$i"
        ((STOPPED++))
    else
        ((NOT_RUNNING++))
    fi
done

echo -e "\n${GREEN}✓ Stopped $STOPPED nodes${NC}"
echo -e "${ORANGE}$NOT_RUNNING nodes were not running${NC}"

# Check if any sessions remain
if tmux ls 2>/dev/null | grep -q "node"; then
    echo -e "\n${ORANGE}Some node sessions still exist:${NC}"
    tmux ls | grep "node"
else
    echo -e "\n${GREEN}✓ All node sessions stopped${NC}"
fi
