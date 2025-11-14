#!/bin/bash

# Start all SilverBitcoin validator nodes (Node01-Node24)
# Node25 is treasury and not started

set -e

# Get the project root directory (2 levels up from scripts/node-management/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🚀 Starting All 10 SilverBitcoin Validator Nodes        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Check if start-node.sh exists
if [ ! -f "scripts/node-management/start-node.sh" ]; then
    echo -e "${RED}❌ start-node.sh not found!${NC}"
    exit 1
fi

# Make start-node.sh executable
chmod +x scripts/node-management/start-node.sh

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}❌ tmux is not installed!${NC}"
    echo -e "${ORANGE}Install: sudo apt install tmux${NC}"
    exit 1
fi

# Check if nodes directory exists
if [ ! -d "nodes" ]; then
    echo -e "${RED}❌ nodes/ directory not found!${NC}"
    echo -e "${ORANGE}Run: ./generate-node-keys.sh${NC}"
    exit 1
fi

STARTED=0
FAILED=0
ALREADY_RUNNING=0

# Start all 10 nodes
for i in {1..10}; do
    echo -e "\n${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${ORANGE}Starting Node$(printf "%02d" $i)...${NC}"
    
    # Check if node directory exists
    NODE_DIR="nodes/Node$(printf "%02d" $i)"
    if [ ! -d "$NODE_DIR" ]; then
        echo -e "${RED}✗ $NODE_DIR not found, skipping...${NC}"
        ((FAILED++))
        continue
    fi
    
    if tmux has-session -t "node$i" 2>/dev/null; then
        echo -e "${ORANGE}✓ Node$i already running${NC}"
        ((ALREADY_RUNNING++))
    else
        if scripts/node-management/start-node.sh $i 2>&1; then
            ((STARTED++))
            # Wait a bit for node to start
            sleep 2
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

# Wait a moment and check if nodes are actually running
if [ $STARTED -gt 0 ]; then
    echo -e "\n${YELLOW}Verifying nodes are running...${NC}"
    sleep 3
    
    VERIFIED=0
    for i in {1..10}; do
        if tmux has-session -t "node$i" 2>/dev/null; then
            ((VERIFIED++))
        fi
    done
    
    echo -e "${GREEN}✓ $VERIFIED nodes verified running${NC}"
    
    if [ $VERIFIED -lt $STARTED ]; then
        echo -e "${RED}⚠ Some nodes may have crashed. Check logs:${NC}"
        echo -e "  ${CYAN}cat nodes/Node01/node.log${NC}"
    fi
fi
