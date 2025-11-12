#!/bin/bash

# Start all SilverBitcoin validator nodes (Node01-Node24)
# Node25 is treasury and not started

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🚀 Starting All SilverBitcoin Validator Nodes           ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Make start-node.sh executable
chmod +x start-node.sh

STARTED=0
FAILED=0
ALREADY_RUNNING=0

# Start nodes 1-24 (skip 25 - treasury)
for i in {1..24}; do
    echo -e "\n${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${ORANGE}Starting Node$(printf "%02d" $i)...${NC}"
    
    if tmux has-session -t "node$i" 2>/dev/null; then
        echo -e "${ORANGE}✓ Node$i already running${NC}"
        ((ALREADY_RUNNING++))
    else
        if ./start-node.sh $i; then
            ((STARTED++))
            sleep 1
        else
            echo -e "${RED}✗ Failed to start Node$i${NC}"
            ((FAILED++))
        fi
    fi
done

echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   📊 Summary                                               ║${NC}"
echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║   ${GREEN}Started: $STARTED${CYAN}                                            ║${NC}"
echo -e "${CYAN}║   ${ORANGE}Already Running: $ALREADY_RUNNING${CYAN}                                ║${NC}"
echo -e "${CYAN}║   ${RED}Failed: $FAILED${CYAN}                                             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}Active tmux sessions:${NC}"
tmux ls 2>/dev/null || echo -e "${ORANGE}No active sessions${NC}"

echo -e "\n${CYAN}Useful commands:${NC}"
echo -e "  ${ORANGE}View all nodes:${NC}     tmux ls"
echo -e "  ${ORANGE}Attach to node:${NC}     tmux attach -t node1"
echo -e "  ${ORANGE}Detach from node:${NC}   Ctrl+B then D"
echo -e "  ${ORANGE}Stop all nodes:${NC}     ./stop-all-nodes.sh"

echo -e "\n${GREEN}✓ Node startup complete!${NC}"
echo -e "${ORANGE}Note: Node25 (Treasury) is not started - it's wallet-only${NC}"
