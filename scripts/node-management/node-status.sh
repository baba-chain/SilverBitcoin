#!/bin/bash

# SilverBitcoin Node Status Checker
# Shows status of all nodes

# Get the project root directory (2 levels up from scripts/node-management/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   📊 SilverBitcoin Node Status                             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

RUNNING=0
STOPPED=0

for i in {1..10}; do
    NODE_NUM=$(printf "%02d" $i)
    NODE_DIR="nodes/Node$NODE_NUM"
    
    if [ ! -d "$NODE_DIR" ]; then
        continue
    fi
    
    # Check if tmux session exists
    if tmux has-session -t "node$i" 2>/dev/null; then
        STATUS="${GREEN}RUNNING${NC}"
        ((RUNNING++))
        
        # Get ports
        HTTP_PORT=$((8545 + i))
        WS_PORT=$((8546 + i))
        P2P_PORT=$((30303 + i))
        
        # Check if port is actually listening
        if command -v netstat &> /dev/null; then
            if netstat -tuln 2>/dev/null | grep -q ":$HTTP_PORT "; then
                PORT_STATUS="${GREEN}✓${NC}"
            else
                PORT_STATUS="${RED}✗${NC}"
            fi
        elif command -v ss &> /dev/null; then
            if ss -tuln 2>/dev/null | grep -q ":$HTTP_PORT "; then
                PORT_STATUS="${GREEN}✓${NC}"
            else
                PORT_STATUS="${RED}✗${NC}"
            fi
        else
            PORT_STATUS="${YELLOW}?${NC}"
        fi
        
        echo -e "Node$NODE_NUM: $STATUS $PORT_STATUS | HTTP:$HTTP_PORT WS:$WS_PORT P2P:$P2P_PORT"
    else
        STATUS="${RED}STOPPED${NC}"
        ((STOPPED++))
        echo -e "Node$NODE_NUM: $STATUS"
    fi
done

echo ""
echo -e "${CYAN}Summary:${NC}"
echo -e "  ${GREEN}Running: $RUNNING${NC}"
echo -e "  ${RED}Stopped: $STOPPED${NC}"
echo ""

if [ $RUNNING -gt 0 ]; then
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  View logs:       ${CYAN}tmux attach -t node1${NC}"
    echo -e "  List sessions:   ${CYAN}tmux ls${NC}"
    echo -e "  Stop all:        ${CYAN}./stop-all-nodes.sh${NC}"
    echo ""
    
    # Try to get block number from first running node
    for i in {1..10}; do
        if tmux has-session -t "node$i" 2>/dev/null; then
            HTTP_PORT=$((8545 + i))
            if command -v curl &> /dev/null; then
                echo -e "${YELLOW}Checking blockchain status (Node$i)...${NC}"
                BLOCK=$(curl -s -X POST -H "Content-Type: application/json" \
                    --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
                    http://localhost:$HTTP_PORT 2>/dev/null | grep -oP '(?<="result":")[^"]+')
                
                if [ ! -z "$BLOCK" ]; then
                    BLOCK_DEC=$((16#${BLOCK#0x}))
                    echo -e "  ${GREEN}Current Block: $BLOCK_DEC${NC}"
                fi
            fi
            break
        fi
    done
fi
