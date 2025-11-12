#!/bin/bash

# Check status of all SilverBitcoin nodes

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   📊 SilverBitcoin Node Status                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

RUNNING=0
STOPPED=0

echo -e "\n${CYAN}Node Status:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

for i in {1..25}; do
    NODE_NAME="Node$(printf "%02d" $i)"
    
    if tmux has-session -t "node$i" 2>/dev/null; then
        if [ $i -eq 25 ]; then
            echo -e "${GREEN}✓ $NODE_NAME${NC} ${ORANGE}(Treasury - Wallet Only)${NC}"
        else
            echo -e "${GREEN}✓ $NODE_NAME${NC} - Running on port $((30303 + i))"
        fi
        ((RUNNING++))
    else
        if [ $i -eq 25 ]; then
            echo -e "${ORANGE}○ $NODE_NAME${NC} ${ORANGE}(Treasury - Not Running)${NC}"
        else
            echo -e "${RED}✗ $NODE_NAME${NC} - Stopped"
        fi
        ((STOPPED++))
    fi
done

echo -e "\n${CYAN}Summary:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Running: $RUNNING${NC}"
echo -e "${RED}Stopped: $STOPPED${NC}"
echo -e "${CYAN}Total: 25 nodes (24 validators + 1 treasury)${NC}"

if [ $RUNNING -gt 0 ]; then
    echo -e "\n${CYAN}Active tmux sessions:${NC}"
    tmux ls 2>/dev/null | grep "node" || true
fi

echo -e "\n${CYAN}Useful commands:${NC}"
echo -e "  ${ORANGE}Start all nodes:${NC}    ./start-all-nodes.sh"
echo -e "  ${ORANGE}Stop all nodes:${NC}     ./stop-all-nodes.sh"
echo -e "  ${ORANGE}Start one node:${NC}     ./start-node.sh <number>"
echo -e "  ${ORANGE}Attach to node:${NC}     tmux attach -t node<number>"
