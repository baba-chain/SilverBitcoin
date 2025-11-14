#!/bin/bash

# SilverBitcoin Discovery Enabler
# Node'ların birbirini otomatik bulması için discovery'yi aktif eder

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
echo -e "${CYAN}║   🔍 Enabling Node Discovery                              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Backup start-node.sh
if [ ! -f "scripts/node-management/start-node.sh.backup" ]; then
    cp scripts/node-management/start-node.sh scripts/node-management/start-node.sh.backup
    echo -e "${GREEN}✓ Backup created: start-node.sh.backup${NC}"
fi

# --nodiscover varsa kaldır, yoksa --netrestrict ekle
if grep -q "\-\-nodiscover" scripts/node-management/start-node.sh; then
    sed -i 's/--nodiscover/--netrestrict 127.0.0.1\/8/g' scripts/node-management/start-node.sh
    echo -e "${GREEN}✓ Removed --nodiscover flag${NC}"
    echo -e "${GREEN}✓ Added --netrestrict 127.0.0.1/8${NC}"
elif ! grep -q "\-\-netrestrict" scripts/node-management/start-node.sh; then
    # --netrestrict yoksa ekle (--networkid satırından sonra)
    sed -i '/--networkid/a\        --netrestrict 127.0.0.1/8 \\' scripts/node-management/start-node.sh
    echo -e "${GREEN}✓ Added --netrestrict 127.0.0.1/8${NC}"
else
    echo -e "${ORANGE}⚠ Discovery already enabled${NC}"
fi

echo -e "\n${CYAN}Changes applied. Now restart all nodes:${NC}"
echo -e "1. ${ORANGE}./stop-all-nodes.sh${NC}"
echo -e "2. ${ORANGE}sleep 2${NC}"
echo -e "3. ${ORANGE}./start-all-nodes.sh${NC}"
echo -e "4. ${ORANGE}./node-status.sh${NC}"

echo -e "\n${CYAN}To restore original:${NC}"
echo -e "${ORANGE}cp scripts/node-management/start-node.sh.backup scripts/node-management/start-node.sh${NC}"
