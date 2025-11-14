#!/bin/bash

# SilverBitcoin Enode Collector
# Tüm node'ların enode adreslerini toplar ve static-nodes.json oluşturur

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   📡 Collecting Enode Addresses                           ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

TEMP_FILE=$(mktemp)
echo "[" > "$TEMP_FILE"

COLLECTED=0
FAILED=0

for i in {1..25}; do
    NODE_NUM=$(printf "%02d" $i)
    HTTP_PORT=$((8545 + i))
    
    echo -e "${CYAN}Collecting Node$NODE_NUM...${NC}"
    
    # Node'un çalışıp çalışmadığını kontrol et
    if ! tmux has-session -t "node$i" 2>/dev/null; then
        echo -e "${ORANGE}  ⚠ Node$NODE_NUM is not running, skipping${NC}"
        ((FAILED++))
        continue
    fi
    
    # Enode adresini al
    ENODE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' \
        http://localhost:$HTTP_PORT 2>/dev/null | \
        grep -o '"enode":"[^"]*"' | \
        cut -d'"' -f4)
    
    if [ -n "$ENODE" ]; then
        echo "  \"$ENODE\"," >> "$TEMP_FILE"
        echo -e "${GREEN}  ✓ $ENODE${NC}"
        ((COLLECTED++))
    else
        echo -e "${RED}  ✗ Failed to get enode${NC}"
        ((FAILED++))
    fi
    
    sleep 0.2
done

# Son virgülü kaldır ve dosyayı kapat
sed -i '$ s/,$//' "$TEMP_FILE"
echo "]" >> "$TEMP_FILE"

# Her node için static-nodes.json'u kopyala
if [ $COLLECTED -gt 0 ]; then
    echo -e "\n${GREEN}Collected $COLLECTED enodes${NC}"
    
    for i in {1..25}; do
        NODE_NUM=$(printf "%02d" $i)
        NODE_DIR="nodes/Node$NODE_NUM"
        
        if [ -d "$NODE_DIR" ]; then
            cp "$TEMP_FILE" "$NODE_DIR/static-nodes.json"
            echo -e "${GREEN}✓ Created static-nodes.json for Node$NODE_NUM${NC}"
        fi
    done
    
    # Ana dizine de kopyala
    cp "$TEMP_FILE" "static-nodes.json"
    echo -e "\n${GREEN}✓ static-nodes.json created successfully${NC}"
    echo -e "${CYAN}Location: $PROJECT_ROOT/static-nodes.json${NC}"
    
    if [ $FAILED -gt 0 ]; then
        echo -e "\n${ORANGE}⚠ $FAILED nodes failed or were not running${NC}"
        echo -e "${ORANGE}You may want to restart all nodes for full connectivity${NC}"
    fi
else
    echo -e "\n${RED}✗ No enodes collected. Make sure nodes are running!${NC}"
    rm "$TEMP_FILE"
    exit 1
fi

rm "$TEMP_FILE"

echo -e "\n${CYAN}Next steps:${NC}"
echo -e "1. ${ORANGE}./stop-all-nodes.sh${NC} - Stop all nodes"
echo -e "2. ${ORANGE}./start-all-nodes.sh${NC} - Restart all nodes"
echo -e "3. ${ORANGE}./node-status.sh${NC} - Check peer connections"
