#!/bin/bash

# Cleanup script for server deployment
# Removes unnecessary files before uploading to server

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🧹 Cleanup for Server Deployment                        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get the project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

echo -e "${YELLOW}Current size:${NC}"
du -sh . 2>/dev/null
echo ""

# Function to remove and report
remove_item() {
    local item=$1
    local description=$2
    
    if [ -e "$item" ]; then
        local size=$(du -sh "$item" 2>/dev/null | cut -f1)
        rm -rf "$item"
        echo -e "${GREEN}✓ Removed $description ($size)${NC}"
    fi
}

echo -e "${YELLOW}Removing build artifacts...${NC}"
remove_item "geth" "Geth binary"
remove_item "bootnode" "Bootnode binary"
remove_item "clef" "Clef binary"
remove_item "evm" "EVM binary"
echo ""

echo -e "${YELLOW}Removing node_modules (will be reinstalled on server)...${NC}"
remove_item "System-Contracts/node_modules" "System-Contracts node_modules"
remove_item "System-Contracts/artifacts" "Hardhat artifacts"
remove_item "System-Contracts/cache" "Hardhat cache"
echo ""

echo -e "${YELLOW}Removing unnecessary files for server...${NC}"
remove_item "phantom_app-25.16.0" "Phantom app (not needed on server)"
remove_item "website" "Website files (not needed on server)"
remove_item "silverbitcoin-node" "Old node files"
echo ""

echo -e "${YELLOW}Removing development files...${NC}"
remove_item ".DS_Store" "macOS files"
find . -name ".DS_Store" -delete 2>/dev/null
find . -name "*.log" -delete 2>/dev/null
find . -name "*.swp" -delete 2>/dev/null
find . -name "*~" -delete 2>/dev/null
echo -e "${GREEN}✓ Temp files removed${NC}"
echo ""

echo -e "${YELLOW}Removing IDE files...${NC}"
remove_item ".vscode" "VSCode settings"
remove_item ".idea" "IntelliJ settings"
remove_item ".kiro" "Kiro settings"
echo ""

echo -e "${YELLOW}Removing backup directories...${NC}"
find . -name "backup-*" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "nodes-backup-*" -type d -exec rm -rf {} + 2>/dev/null || true
echo -e "${GREEN}✓ Backup directories removed${NC}"
echo ""

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ✅ Cleanup Complete!                                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Size after cleanup:${NC}"
du -sh . 2>/dev/null
echo ""

echo -e "${GREEN}Ready for server deployment!${NC}"
echo ""
echo -e "${YELLOW}What was removed:${NC}"
echo -e "  • Go binaries (will be built on server)"
echo -e "  • node_modules (will be installed on server)"
echo -e "  • Phantom app (not needed on server)"
echo -e "  • Website files (not needed on server)"
echo -e "  • Development files and caches"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Commit changes: ${CYAN}git add . && git commit -m 'Cleanup for deployment'${NC}"
echo -e "  2. Push to GitHub: ${CYAN}git push${NC}"
echo -e "  3. On server: ${CYAN}git clone && scripts/setup/setup-blockchain-complete.sh${NC}"
