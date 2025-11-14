#!/bin/bash

# Reth Node Status Checker

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🦀 Reth Node Status                                      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if tmux session exists
if tmux has-session -t "reth-node" 2>/dev/null; then
    echo -e "Status: ${GREEN}RUNNING ✓${NC}"
    
    HTTP_PORT=9545
    
    # Check if port is listening
    if command -v netstat &> /dev/null; then
        if netstat -tuln 2>/dev/null | grep -q ":$HTTP_PORT "; then
            echo -e "HTTP Port: ${GREEN}LISTENING ✓${NC}"
        else
            echo -e "HTTP Port: ${RED}NOT LISTENING ✗${NC}"
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln 2>/dev/null | grep -q ":$HTTP_PORT "; then
            echo -e "HTTP Port: ${GREEN}LISTENING ✓${NC}"
        else
            echo -e "HTTP Port: ${RED}NOT LISTENING ✗${NC}"
        fi
    fi
    
    # Try to get block number
    if command -v curl &> /dev/null; then
        echo ""
        echo -e "${YELLOW}Blockchain Status:${NC}"
        
        BLOCK=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            http://localhost:$HTTP_PORT 2>/dev/null | grep -oP '(?<="result":")[^"]+')
        
        if [ ! -z "$BLOCK" ]; then
            BLOCK_DEC=$((16#${BLOCK#0x}))
            echo -e "  Current Block: ${GREEN}$BLOCK_DEC${NC}"
        else
            echo -e "  ${YELLOW}Waiting for RPC...${NC}"
        fi
        
        # Get peer count
        PEERS=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
            http://localhost:$HTTP_PORT 2>/dev/null | grep -oP '(?<="result":")[^"]+')
        
        if [ ! -z "$PEERS" ]; then
            PEERS_DEC=$((16#${PEERS#0x}))
            echo -e "  Peer Count: ${GREEN}$PEERS_DEC${NC}"
        fi
        
        # Get syncing status
        SYNCING=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
            http://localhost:$HTTP_PORT 2>/dev/null | grep -oP '(?<="result":)[^,}]+')
        
        if [ "$SYNCING" == "false" ]; then
            echo -e "  Sync Status: ${GREEN}SYNCED ✓${NC}"
        else
            echo -e "  Sync Status: ${YELLOW}SYNCING...${NC}"
        fi
    fi
    
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo -e "  Attach to console: ${YELLOW}tmux attach -t reth-node${NC}"
    echo -e "  View logs:         ${YELLOW}tail -f reth-data/reth.log${NC}"
    echo -e "  Stop node:         ${YELLOW}./stop-reth-node.sh${NC}"
else
    echo -e "Status: ${RED}STOPPED ✗${NC}"
    echo ""
    echo -e "${CYAN}To start:${NC} ${YELLOW}./start-reth-node.sh${NC}"
fi

echo ""
