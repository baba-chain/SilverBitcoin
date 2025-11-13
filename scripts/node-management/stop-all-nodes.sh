#!/bin/bash

# Stop all SilverBitcoin nodes

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
echo -e "${CYAN}║   🛑 Stopping All SilverBitcoin Nodes                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}❌ tmux is not installed!${NC}"
    exit 1
fi

STOPPED=0
NOT_RUNNING=0

for i in {1..25}; do
    if tmux has-session -t "node$i" 2>/dev/null; then
        echo -e "${ORANGE}Stopping Node$(printf "%02d" $i)...${NC}"
        tmux kill-session -t "node$i" 2>/dev/null || true
        ((STOPPED++))
        sleep 0.5
    else
        ((NOT_RUNNING++))
    fi
done

echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   📊 Summary                                               ║${NC}"
echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║   ${GREEN}Stopped: $STOPPED${CYAN}                                           ║${NC}"
echo -e "${CYAN}║   ${ORANGE}Not Running: $NOT_RUNNING${CYAN}                                    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Wait a moment and verify
if [ $STOPPED -gt 0 ]; then
    echo -e "\n${YELLOW}Verifying nodes stopped...${NC}"
    sleep 2
    
    STILL_RUNNING=0
    for i in {1..25}; do
        if tmux has-session -t "node$i" 2>/dev/null; then
            echo -e "${RED}⚠ Node$i still running${NC}"
            ((STILL_RUNNING++))
        fi
    done
    
    if [ $STILL_RUNNING -eq 0 ]; then
        echo -e "${GREEN}✓ All nodes stopped successfully${NC}"
    else
        echo -e "${RED}⚠ $STILL_RUNNING nodes still running${NC}"
        echo -e "${YELLOW}Try: tmux kill-server (stops all tmux sessions)${NC}"
    fi
fi

# Check if any node sessions remain
if tmux ls 2>/dev/null | grep -q "node"; then
    echo -e "\n${ORANGE}Remaining node sessions:${NC}"
    tmux ls 2>/dev/null | grep "node" || true
fi
