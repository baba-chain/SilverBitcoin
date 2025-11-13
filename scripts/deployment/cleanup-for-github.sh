#!/bin/bash

# SilverBitcoin - GitHub Cleanup Script
# Bu script gereksiz dosyaları siler, sadece blockchain core files kalır

set -e

# Get the project root directory
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
echo -e "${CYAN}║   🧹 SilverBitcoin - GitHub Cleanup Script                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}⚠️  WARNING: This will delete unnecessary files!${NC}"
echo -e "${YELLOW}Only blockchain core files will remain.${NC}"
echo -e "\n${CYAN}Files to be deleted:${NC}"
echo -e "  - Web platforms (Presale, Staking, etc.)"
echo -e "  - Deployment configs"
echo -e "  - Extra documentation"
echo -e "  - Utility scripts"
echo -e "  - Development files"

echo -e "\n${RED}Do you want to continue?${NC}"
read -p "Type 'yes' to confirm: " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled.${NC}"
    exit 0
fi

echo -e "\n${YELLOW}Creating backup...${NC}"
BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "../$BACKUP_DIR"
cp -r . "../$BACKUP_DIR/"
echo -e "${GREEN}✅ Backup created at ../$BACKUP_DIR${NC}"

echo -e "\n${YELLOW}[1/8] Removing development files...${NC}"
rm -rf node_modules/ .DS_Store .vscode/ .kiro/ 2>/dev/null || true
echo -e "${GREEN}✅ Development files removed${NC}"

echo -e "\n${YELLOW}[2/8] Removing web platforms...${NC}"
rm -rf Presale/ staking-dashboard/ staking-dashboard-host/ 2>/dev/null || true
rm -rf validator-dashboard/ validator-dashboard-host/ 2>/dev/null || true
rm -rf web/ whitepaper/ 2>/dev/null || true
rm -f index.html styles.css logo.png Page1.jpg 2>/dev/null || true
echo -e "${GREEN}✅ Web platforms removed${NC}"

echo -e "\n${YELLOW}[3/8] Removing deployment configs...${NC}"
rm -rf deployment/ auto-start/ monitoring/ verification/ updates/ 2>/dev/null || true
rm -rf tools/ docs/ silverbitcoin-node/ 2>/dev/null || true
echo -e "${GREEN}✅ Deployment configs removed${NC}"

echo -e "\n${YELLOW}[4/8] Removing extra documentation...${NC}"
rm -f COMPLETE-DEPLOYMENT-GUIDE.md DEPLOYMENT-STRATEGY.md 2>/dev/null || true
rm -f DEPLOYMENT-SUMMARY.md FINAL-COMPLETE-GUIDE.md 2>/dev/null || true
rm -f HASH-AND-BUTTON-FIX.md HOSTINGER-*.md 2>/dev/null || true
rm -f LANDING-PAGE-README.md LOCAL-TESTNET-SETUP.md 2>/dev/null || true
rm -f LOGO-IMAGE-FIX.md NODE-STRUCTURE.md NODES-README.md 2>/dev/null || true
rm -f ONCLICK-FIX.md SHOW-ALL-WALLETS-FIX.md 2>/dev/null || true
rm -f STATIC-*.md SYNC-HELPER-SETUP.md 2>/dev/null || true
rm -f WALLET-*.md WEB3-LOADING-FIX.md 2>/dev/null || true
rm -f SUNUCU-KURULUM-OZET.md 2>/dev/null || true
echo -e "${GREEN}✅ Extra documentation removed${NC}"

echo -e "\n${YELLOW}[5/8] Removing utility scripts...${NC}"
rm -f eth-adress.py simple-address.py 2>/dev/null || true
rm -f generate-*.py generate-*.sh 2>/dev/null || true
rm -f create-release.sh setup-static-*.sh 2>/dev/null || true
rm -f start-node-simple.sh hardhat-deploy-script.js 2>/dev/null || true
rm -f app.js public_html_htaccess_fix.txt 2>/dev/null || true
echo -e "${GREEN}✅ Utility scripts removed${NC}"

echo -e "\n${YELLOW}[6/8] Removing data files...${NC}"
rm -f genesis-nodes-public.txt genesis-nodes.csv 2>/dev/null || true
rm -f validator-addresses.txt package-lock.json 2>/dev/null || true
echo -e "${GREEN}✅ Data files removed${NC}"

echo -e "\n${YELLOW}[7/8] Cleaning node directories...${NC}"
# Keep structure but remove data
for i in {1..25}; do
    NODE_NUM=$(printf "%02d" $i)
    NODE_DIR="nodes/Node$NODE_NUM"
    if [ -d "$NODE_DIR" ]; then
        # Remove blockchain data but keep address.txt and info.txt
        rm -rf "$NODE_DIR/geth" "$NODE_DIR/keystore" 2>/dev/null || true
        rm -f "$NODE_DIR/private_key.txt" "$NODE_DIR/password.txt" 2>/dev/null || true
    fi
done
echo -e "${GREEN}✅ Node directories cleaned${NC}"

echo -e "\n${YELLOW}[8/8] Organizing documentation...${NC}"
# Keep only essential docs
mkdir -p docs/ 2>/dev/null || true
mv GITHUB-*.md docs/ 2>/dev/null || true
echo -e "${GREEN}✅ Documentation organized${NC}"

# Show remaining structure
echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ✅ Cleanup Complete!                                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}Remaining structure:${NC}"
echo -e "${CYAN}SilverBitcoin/${NC}"
echo -e "  ├── SilverBitcoin/          ${GREEN}(Geth source)${NC}"
echo -e "  ├── System-Contracts/       ${GREEN}(Smart contracts)${NC}"
echo -e "  ├── nodes/                  ${GREEN}(Node structure)${NC}"
echo -e "  ├── docs/                   ${GREEN}(Documentation)${NC}"
echo -e "  ├── *.sh                    ${GREEN}(Management scripts)${NC}"
echo -e "  ├── genesis.json            ${GREEN}(Genesis block)${NC}"
echo -e "  ├── README.md               ${GREEN}(Main docs)${NC}"
echo -e "  └── .gitignore              ${GREEN}(Git rules)${NC}"

echo -e "\n${YELLOW}Backup location:${NC} ../$BACKUP_DIR"
echo -e "${YELLOW}Repository size:${NC} $(du -sh . | cut -f1)"

echo -e "\n${GREEN}Ready to push to GitHub! 🚀${NC}"
echo -e "${CYAN}Next steps:${NC}"
echo -e "  1. Review changes: ${YELLOW}git status${NC}"
echo -e "  2. Push to GitHub: ${YELLOW}./push-to-github.sh${NC}"
