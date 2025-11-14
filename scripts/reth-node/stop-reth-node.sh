#!/bin/bash

# Reth Node Stopper

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Stopping Reth node...${NC}"

if tmux has-session -t "reth-node" 2>/dev/null; then
    tmux kill-session -t "reth-node"
    echo -e "${GREEN}✓ Reth node stopped${NC}"
else
    echo -e "${RED}✗ Reth node is not running${NC}"
fi
