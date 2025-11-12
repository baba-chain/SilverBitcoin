#!/bin/bash

# Stop a specific SilverBitcoin node
# Usage: ./stop-node.sh <node_number>

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}Error: Node number required${NC}"
    echo -e "Usage: $0 <node_number>"
    echo -e "Example: $0 1"
    exit 1
fi

NODE_NUM=$1

if tmux has-session -t "node$NODE_NUM" 2>/dev/null; then
    echo -e "${ORANGE}Stopping Node$NODE_NUM...${NC}"
    tmux kill-session -t "node$NODE_NUM"
    echo -e "${GREEN}✓ Node$NODE_NUM stopped${NC}"
else
    echo -e "${ORANGE}Node$NODE_NUM is not running${NC}"
fi
